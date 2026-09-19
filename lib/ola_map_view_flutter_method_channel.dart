/// Default method-channel implementation of [OlaMapViewFlutterPlatform].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ola_map_view_flutter_platform_interface.dart';

/// An implementation of [OlaMapViewFlutterPlatform] that uses method channels.
class MethodChannelOlaMapViewFlutter extends OlaMapViewFlutterPlatform {
  /// Creates the default method-channel backend.
  MethodChannelOlaMapViewFlutter();
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ola_map_view_flutter');

  /// Invokes `getPlatformVersion` on the host platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
