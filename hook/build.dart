import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final packageRoot = input.packageRoot.toFilePath();
    final buildDir = Directory(
      '${input.outputDirectoryShared.toFilePath()}/llama_build',
    )..createSync(recursive: true);

    final nativeDir = '$packageRoot/native';
    final llamaCppDir = '$packageRoot/third_party/llama.cpp';

    final cmakeConfigure = await Process.run('cmake', [
      '-S',
      nativeDir,
      '-B',
      buildDir.path,
      '-DLLAMA_CPP_DIR=$llamaCppDir',
      '-DCMAKE_BUILD_TYPE=Release',
    ], workingDirectory: packageRoot);

    if (cmakeConfigure.exitCode != 0) {
      stderr.write(cmakeConfigure.stdout);
      stderr.write(cmakeConfigure.stderr);
      throw Exception('CMake configure failed');
    }

    final cmakeBuild = await Process.run('cmake', [
      '--build',
      buildDir.path,
      '--config',
      'Release',
    ], workingDirectory: packageRoot);

    if (cmakeBuild.exitCode != 0) {
      stderr.write(cmakeBuild.stdout);
      stderr.write(cmakeBuild.stderr);
      throw Exception('CMake build failed');
    }

    final dylibName = switch (input.config.code.targetOS) {
      OS.macOS => 'libllama_dart.dylib',
      OS.linux => 'libllama_dart.so',
      OS.windows => 'llama_dart.dll',
      _ => throw UnsupportedError('This example only targets desktop for now.'),
    };

    final builtLib = Uri.file('${buildDir.path}/$dylibName');

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'llama_bindings.g.dart',
        linkMode: DynamicLoadingBundled(),
        file: builtLib,
      ),
    );
  });
}
