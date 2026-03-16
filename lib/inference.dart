import 'dart:ffi';
import 'dart:convert';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:llama_inference/llama_bindings.g.dart';

Future<String> inference({required String prompt, required String modelPath}) async {
  final modelPathUtf = modelPath.toNativeUtf8();
  final llamaHandlePtr = llama_dart_create(modelPathUtf.cast<Char>(), 2048, 4);
  if (llamaHandlePtr == nullptr) {
    print('LLAMA FAILED TO REGISTER');
    return 'Failed to register model';
  }
  malloc.free(modelPathUtf);

  // Generate.
  final prompt = "Hello! How are you?".toNativeUtf8().cast<Char>();
  final outputBuf = malloc<Uint8>(16 * 1024);

  final written = llama_dart_generate(
    llamaHandlePtr,
    prompt,
    128 * 2,
    outputBuf.cast<Char>(),
    16 * 1024,
  );

  // print('WRITTEN RESULT: $written');

  malloc.free(prompt);

  if (written < 0) {
    malloc.free(outputBuf);
    llama_dart_destroy(llamaHandlePtr);
    print('Generation failed with code $written');
    exit(1);
  }

  final bytes = outputBuf.asTypedList(written);
  final outputString = utf8.decode(bytes);
  // print('OUTPUT: $outputString');

  malloc.free(outputBuf);

  // Destroy the shit.
  llama_dart_destroy(llamaHandlePtr);

  return outputString;
}