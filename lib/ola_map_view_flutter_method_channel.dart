import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ola_map_view_flutter_platform_interface.dart';

/// An implementation of [OlaMapViewFlutterPlatform] that uses method channels.
class MethodChannelOlaMapViewFlutter extends OlaMapViewFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ola_map_view_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
