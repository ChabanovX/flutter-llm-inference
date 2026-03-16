import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:llama_inference/inference.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(home: Page());
  }
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> {
  Future<String>? promptResult;

  Future<String>? modelPathFuture;
  String? modelPath;

  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<String?> prepareModelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );

    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return null;

    final appSupport = await getApplicationSupportDirectory();
    final modelsDir = Directory(p.join(appSupport.path, 'models'));
    await modelsDir.create(recursive: true);

    final targetPath = p.join(modelsDir.path, p.basename(pickedPath));
    await File(pickedPath).copy(targetPath);

    return targetPath;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(
        largeTitle: FutureBuilder(future: modelPathFuture, builder: (context, snap) {
          if (snap.hasData) {
            modelPath = snap.data;
            return Text('Selected path: ${snap.data}');
          } return Row(
            children: [
              Text('Select a model path: '),
              CupertinoButton(sizeStyle: .small, onPressed: prepareModelFile, child: Text('Select'))
            ],
          );
        }),
      ),
      child: Center(
        child: Container(
          padding: .symmetric(horizontal: 64),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              CupertinoTextField(
                placeholder: 'Input a prompt',
                controller: _textEditingController,
              ),
              Align(
                alignment: .centerRight,
                child: CupertinoButton(
                  child: Text('Generate'),
                  onPressed: () {
                    promptResult = inference(prompt: _textEditingController.text, modelPath: modelPath!);
                  },
                ),
              ),
              SizedBox(height: 32),
              FutureBuilder(
                future: promptResult,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('Result: ${snapshot.data}');
                  }
                  return Text('Waiting for the prompt...');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
