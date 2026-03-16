import 'package:llama_inference/inference.dart';

void main() async {
  print(await inference(prompt: 'Hello!', modelPath: 'your/model/path'));
}
