#include "llama_dart.h"

#include <cstring>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "llama.h"

struct llama_dart_handle {
  llama_model* model = nullptr;
  llama_context* ctx = nullptr;
  const llama_vocab* vocab = nullptr;
  int32_t n_ctx = 0;
};

static std::string truncate_to_fit(const std::string& s, int32_t out_buf_len) {
  if (out_buf_len <= 0) return "";
  if ((int32_t)s.size() < out_buf_len) return s;
  return s.substr(0, out_buf_len - 1);
}

llama_dart_handle* llama_dart_create(
    const char* model_path,
    int32_t n_ctx,
    int32_t n_threads) {
  if (!model_path) return nullptr;

  llama_backend_init();

  auto* handle = new llama_dart_handle();
  handle->n_ctx = n_ctx;

  llama_model_params model_params = llama_model_default_params();
  handle->model = llama_model_load_from_file(model_path, model_params);
  if (!handle->model) {
    delete handle;
    return nullptr;
  }

  llama_context_params ctx_params = llama_context_default_params();
  ctx_params.n_ctx = n_ctx;
  ctx_params.n_threads = n_threads;
  ctx_params.n_threads_batch = n_threads;

  handle->ctx = llama_init_from_model(handle->model, ctx_params);
  if (!handle->ctx) {
    llama_model_free(handle->model);
    delete handle;
    return nullptr;
  }

  handle->vocab = llama_model_get_vocab(handle->model);
  return handle;
}

void llama_dart_destroy(llama_dart_handle* handle) {
  if (!handle) return;
  if (handle->ctx) llama_free(handle->ctx);
  if (handle->model) llama_model_free(handle->model);
  delete handle;
  llama_backend_free();
}

// Super-minimal greedy generation example.
// Real apps should add BOS/EOS handling, chat templates, sampling config,
// KV-cache reuse, batching, stop sequences, error handling, etc.
int32_t llama_dart_generate(
    llama_dart_handle* handle,
    const char* prompt,
    int32_t max_tokens,
    char* out_buf,
    int32_t out_buf_len) {
  if (!handle || !prompt || !out_buf || out_buf_len <= 0) return -1;

  std::string result;

  // Tokenize prompt
  const bool add_special = true;
  const bool parse_special = true;

  int32_t n_prompt = -llama_tokenize(
      handle->vocab,
      prompt,
      (int32_t)std::strlen(prompt),
      nullptr,
      0,
      add_special,
      parse_special);

  if (n_prompt <= 0) return -2;

  std::vector<llama_token> prompt_tokens(n_prompt);
  const int32_t actual_prompt = llama_tokenize(
      handle->vocab,
      prompt,
      (int32_t)std::strlen(prompt),
      prompt_tokens.data(),
      (int32_t)prompt_tokens.size(),
      add_special,
      parse_special);

  if (actual_prompt < 0) return -3;

  llama_batch batch = llama_batch_init(actual_prompt, 0, 1);
  batch.n_tokens = actual_prompt;
  for (int i = 0; i < actual_prompt; ++i) {
    batch.token[i] = prompt_tokens[i];
    batch.pos[i] = i;
    batch.n_seq_id[i] = 1;
    batch.seq_id[i][0] = 0;
    batch.logits[i] = (i == actual_prompt - 1);
  }

  if (llama_decode(handle->ctx, batch) != 0) {
    llama_batch_free(batch);
    return -4;
  }
  llama_batch_free(batch);

  llama_token new_token_id = 0;
  int32_t cur_pos = actual_prompt;

  for (int32_t step = 0; step < max_tokens; ++step) {
    const float* logits = llama_get_logits(handle->ctx);
    if (!logits) break;

    const int32_t vocab_n = llama_vocab_n_tokens(handle->vocab);

    // Greedy pick.
    int best_id = 0;
    float best_logit = logits[0];
    for (int i = 1; i < vocab_n; ++i) {
      if (logits[i] > best_logit) {
        best_logit = logits[i];
        best_id = i;
      }
    }

    new_token_id = best_id;

    if (llama_vocab_is_eog(handle->vocab, new_token_id)) {
      break;
    }

    char piece[16 * 1024];
    const int32_t piece_len = llama_token_to_piece(
        handle->vocab,
        new_token_id,
        piece,
        (int32_t)sizeof(piece),
        0,
        true);

    if (piece_len > 0) {
      result.append(piece, piece_len);
    }

    llama_batch step_batch = llama_batch_init(1, 0, 1);
    step_batch.n_tokens = 1;
    step_batch.token[0] = new_token_id;
    step_batch.pos[0] = cur_pos++;
    step_batch.n_seq_id[0] = 1;
    step_batch.seq_id[0][0] = 0;
    step_batch.logits[0] = 1;

    if (llama_decode(handle->ctx, step_batch) != 0) {
      llama_batch_free(step_batch);
      break;
    }
    llama_batch_free(step_batch);
  }

  const std::string final_text = truncate_to_fit(result, out_buf_len);
  std::memcpy(out_buf, final_text.c_str(), final_text.size());
  out_buf[final_text.size()] = '\0';

  return (int32_t)final_text.size();
}
