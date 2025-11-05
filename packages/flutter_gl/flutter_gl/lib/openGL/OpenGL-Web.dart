import 'dart:html';
// ignore: uri_does_not_exist
import 'dart:ui_web' as ui_web;

import './OpenGL-Base.dart';
import 'opengl/OpenGLContextES.dart'
    if (dart.library.js) 'opengl/OpenGLContextWeb.dart';

getInstance(Map<String, dynamic> options) {
  return OpenGLWeb(options);
}

class OpenGLWeb extends OpenGLBase {
  late int width;
  late int height;

  late String divId;
  num dpr = 1.0;
  dynamic _gl;
  bool _alpha = false;
  bool _antialias = false;
  bool _debug = false;

  dynamic get gl {
    if (_gl == null) {
      final context = getContext({
        "gl": element.getContext(
            "webgl2", {"alpha": _alpha, "antialias": _antialias}),
        "debug": _debug,
      });
      _gl = context;
    }

    return _gl;
  }

  OpenGLWeb(Map<String, dynamic> options) : super(options) {
    this._alpha = options["alpha"] ?? false;
    this._antialias = options["antialias"] ?? false;
    this.width = options["width"];
    this.height = options["height"];
    this.divId = options["divId"];
    this.dpr = options["dpr"] ?? window.devicePixelRatio;
    this._debug = options["debug"] ?? false;

    final CanvasElement domElement = CanvasElement(
        width: (width * dpr).toInt(), height: (height * dpr).toInt())
      ..id = 'canvas-id';

    domElement.style
      ..width = '${width}px'
      ..height = '${height}px'
      ..display = 'block';

    final DivElement container = DivElement()
      ..style.width = '${width}px'
      ..style.height = '${height}px'
      ..style.display = 'block'
      ..style.overflow = 'hidden';
    container.append(domElement);

    this.element = domElement;

    ui_web.platformViewRegistry.registerViewFactory(divId, (int viewId) {
      return container;
    });
  }

  makeCurrent(List<int> egls) {
    // web no need do something
  }
}
