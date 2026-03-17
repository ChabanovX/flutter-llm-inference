import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('src/llama_dart.h')],
    ),
    functions: Functions.includeSet({'llama_dart_create', 'llama_dart_destroy', 'llama_dart_generate'}),
    output: Output(
      dartFile: packageRoot.resolve('lib/llama_bindings.g.dart'),
    ),
  ).generate();
}