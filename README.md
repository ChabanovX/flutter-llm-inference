# llama_inference

Dart FFI package that loads llama.cpp runtime and runs it via FFI calls. Uses build hooks for linking code assets.

## Getting Started

Firstly, adjust variables inside `lib/main.dart`.

Run:

```sh
dart run lib/main.dart
```

After that, you might explore example of usage of this bindings inside a Flutter app.
```sh
cd example && flutter run -d macos
```

## Example

![example](docs/gen_example.png)

## Limitations

Current approach does not handle inference well: it skips EOS, uses greedy sampling and does not support token streaming. Adjust inference for your use case in `src/llama_dart.cpp`

Also, in Flutter apps you should handle model loading by yourself, whether you are going to load it from internet or ship it with the app's binary. In `example/` I pick model which exists on my computer.