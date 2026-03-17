#ifndef LLAMA_DART_H
#define LLAMA_DART_H

#include <stdint.h>

#ifdef _WIN32
  #define LLAMA_DART_EXPORT __declspec(dllexport)
#else
  #define LLAMA_DART_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct llama_dart_handle llama_dart_handle;

LLAMA_DART_EXPORT llama_dart_handle* llama_dart_create(
    const char* model_path,
    int32_t n_ctx,
    int32_t n_threads);

LLAMA_DART_EXPORT void llama_dart_destroy(
    llama_dart_handle* handle);

LLAMA_DART_EXPORT int32_t llama_dart_generate(
    llama_dart_handle* handle,
    const char* prompt,
    int32_t max_tokens,
    char* out_buf,
    int32_t out_buf_len);

#ifdef __cplusplus
}
#endif

#endif