import 'package:flutter/services.dart';
import 'package:ola_maps/src/web/ola_maps_web_host.dart';

Future<dynamic> olaMapInvoke(int id, String method, [dynamic arguments]) {
  final host = OlaMapsWebHost.get(id);
  if (host == null) {
    throw PlatformException(
      code: 'MAP_NOT_FOUND',
      message: 'Web map instance not found for id: $id',
    );
  }
  return host.handle(method, arguments);
}

void olaMapListen(
  int id,
  Future<dynamic> Function(MethodCall call)? handler,
) {
  OlaMapsWebHost.get(id)?.eventHandler = handler;
}

Stream<dynamic>? olaMapCameraStream(int id) => null;

void olaMapDisposeChannel(int id) {
  OlaMapsWebHost.get(id)?.dispose();
}
