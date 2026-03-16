import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:llama_inference/llama_bindings.g.dart';

void main() {
  // Create.
  final modelPath = "/Users/chabanovz/.ollama/models/blobs/sha256-afb707b6b8fac6e475acc42bc8380fc0b8d2e0e4190be5a969fbf62fcc897db5".toNativeUtf8();
  final llamaHandle = llama_dart_create(modelPath.cast<Char>(), 2048, 4);
  malloc.free(modelPath);

  // Generate.
  final prompt = "Hello! How are you?".toNativeUtf8().cast<Char>();
  final outputBuf = malloc<Char>(16 * 1024);

  final written = llama_dart_generate(
    llamaHandle,
    prompt,
    128,
    outputBuf,
    16 * 1024,
  );

  print('Written result: $written');

  malloc.free(prompt);

  final outputString = outputBuf.cast<Utf8>().toDartString();
  print(outputString);

  malloc.free(outputBuf);

  // Destroy the shit.
  llama_dart_destroy(llamaHandle);
}
