import 'package:flutter/services.dart';

Future<dynamic> olaMapInvoke(int id, String method, [dynamic arguments]) {
  return MethodChannel('ola_map_view_flutter_$id').invokeMethod(method, arguments);
}

void olaMapListen(
  int id,
  Future<dynamic> Function(MethodCall call)? handler,
) {
  MethodChannel('ola_map_view_flutter_$id').setMethodCallHandler(handler);
}

Stream<dynamic>? olaMapCameraStream(int id) {
  return EventChannel('ola_map_view_flutter_camera_$id').receiveBroadcastStream();
}

void olaMapDisposeChannel(int id) {
  MethodChannel('ola_map_view_flutter_$id').setMethodCallHandler(null);
}
