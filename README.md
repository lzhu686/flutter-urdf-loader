# flutter-urdf-loader

A workspace that bundles the `urdf_parser` library and the `flutter_gl` plugin so they can be consumed together for Flutter-based URDF rendering on mobile, desktop, and web.

This repository captures local fixes required for WebGL support (Wasabia fork) and URDF parsing updates while keeping the original projects' history and licenses visible inside `packages/`.

## Layout

- `packages/flutter_urdf_parser/` – fork of [JayKay135/flutter-urdf-parser](https://github.com/JayKay135/flutter-urdf-parser) with web-specific fixes and file loader abstraction.
- `packages/flutter_gl/` – fork of [wasabia/flutter_gl](https://github.com/wasabia/flutter_gl) (commit a5b8ff7…) containing WebGL view registration updates.
- `packages/flutter_urdf_parser/example/` – sample Flutter application demonstrating URDF rendering on the web via the local packages.

## Using the packages

In your Flutter project `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  urdf_parser:
    path: packages/flutter_urdf_parser

dependency_overrides:
  flutter_gl:
    path: packages/flutter_gl/flutter_gl
```

> The parser depends on `flutter_gl` and `three_dart` git revisions (Wasabia) to enable web rendering. The override keeps everything within this mono-repo.

After updating dependencies, run:

```bash
flutter pub get
flutter run -d chrome
```

## Licenses & Credits

Each package keeps its original `LICENSE` file. Please refer to:

- [`packages/flutter_urdf_parser/LICENSE`](packages/flutter_urdf_parser/LICENSE) (MIT, © JayKay135 and contributors)
- [`packages/flutter_gl/LICENSE`](packages/flutter_gl/LICENSE) (MIT, © FutuoApp/Wasabia and contributors)

Additional modifications in this workspace are released under the MIT license; see [LICENSE](LICENSE).

Acknowledgements:

- [JayKay135/flutter-urdf-parser](https://github.com/JayKay135/flutter-urdf-parser)
- [wasabia/flutter_gl](https://github.com/wasabia/flutter_gl)

## Development notes

- Web support depends on `flutter run -d chrome`.
- Linux currently lacks native `flutter_gl` bindings; guard usage or add a Linux plugin implementation before enabling.
- The parser now relies on `file_loader.dart`'s conditional export (`dart:io` vs HTTP) to load URDF meshes across platforms.
