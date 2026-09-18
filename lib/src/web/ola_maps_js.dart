import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

const kOlaMapsWebSdkUrl =
    'https://www.unpkg.com/olamaps-web-sdk@1.4.0/dist/olamaps-web-sdk.umd.js';
const kOlaMapsWebCssUrl =
    'https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css';

Future<void>? _loading;

Future<void> ensureOlaMapsWebSdkLoaded() {
  return _loading ??= _load();
}

JSFunction? olaMapsCtor() {
  final sdk = globalContext.getProperty('OlaMapsSDK'.toJS);
  if (sdk.isA<JSObject>()) {
    final ctor = (sdk as JSObject).getProperty('OlaMaps'.toJS);
    if (ctor.isA<JSFunction>()) return ctor as JSFunction;
  }
  final direct = globalContext.getProperty('OlaMaps'.toJS);
  if (direct.isA<JSFunction>()) return direct as JSFunction;
  if (direct.isA<JSObject>()) {
    final nested = (direct as JSObject).getProperty('OlaMaps'.toJS);
    if (nested.isA<JSFunction>()) return nested as JSFunction;
  }
  return null;
}

JSAny? jsValue(Object? value) {
  if (value == null) return null;
  if (value is JSAny) return value;
  if (value is String) return value.toJS;
  if (value is num) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is List) {
    return value.map(jsValue).toList().toJS;
  }
  if (value is Map) {
    final object = JSObject();
    value.forEach((key, item) {
      object.setProperty(key.toString().toJS, jsValue(item));
    });
    return object;
  }
  return value.jsify();
}

JSObject jsObject(Map<String, Object?> value) => jsValue(value)! as JSObject;

num? jsNum(JSAny? value) {
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.isA<JSNumber>()) return (value as JSNumber).toDartDouble;
  return num.tryParse(value.toString());
}

String? jsString(JSAny? value) {
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.isA<JSString>()) return (value as JSString).toDart;
  return value.toString();
}

JSObject? asJsObject(JSAny? value) {
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.isA<JSObject>()) return value as JSObject;
  return null;
}

Future<JSAny?> awaitJs(JSAny? value) async {
  if (value == null) return null;
  if (value.isA<JSPromise>()) {
    return await (value as JSPromise).toDart;
  }
  return value;
}

JSObject constructOlaMaps(Map<String, Object?> options) {
  final ctor = olaMapsCtor();
  if (ctor == null) {
    throw StateError('Ola Maps Web SDK did not expose OlaMaps');
  }
  return ctor.callAsConstructor(jsObject(options)) as JSObject;
}

Future<void> _load() async {
  _injectCss(kOlaMapsWebCssUrl, 'data-ola-maps-css');
  _injectCss(_mapCss, 'data-ola-maps-inline-css', inline: true);
  if (olaMapsCtor() != null) return;

  final existing = web.document.querySelector('script[data-ola-maps-sdk]');
  if (existing != null) {
    await _waitForCtor();
    return;
  }

  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = kOlaMapsWebSdkUrl
    ..async = true;
  script.setAttribute('data-ola-maps-sdk', 'true');
  script.addEventListener(
    'load',
    (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS,
  );
  script.addEventListener(
    'error',
    (web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Failed to load Ola Maps Web SDK from $kOlaMapsWebSdkUrl'),
        );
      }
    }.toJS,
  );
  web.document.head?.append(script);
  await completer.future;
  await _waitForCtor();
}

Future<void> _waitForCtor() async {
  for (var i = 0; i < 50; i++) {
    if (olaMapsCtor() != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw StateError(
    'Ola Maps Web SDK loaded but window.OlaMapsSDK.OlaMaps was not found',
  );
}

void _injectCss(String hrefOrCss, String marker, {bool inline = false}) {
  if (web.document.querySelector('[$marker]') != null) return;
  if (inline) {
    final style = web.HTMLStyleElement()..text = hrefOrCss;
    style.setAttribute(marker, 'true');
    web.document.head?.append(style);
    return;
  }
  final link = web.HTMLLinkElement()
    ..rel = 'stylesheet'
    ..href = hrefOrCss;
  link.setAttribute(marker, 'true');
  web.document.head?.append(link);
}

const _mapCss = '''
.maplibregl-map, .mapboxgl-map {
  width: 100%;
  height: 100%;
}
.maplibregl-canvas, .mapboxgl-canvas {
  outline: none;
}
''';
