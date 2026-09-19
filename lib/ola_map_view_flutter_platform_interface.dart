/// Platform interface for the Ola Maps Flutter plugin.
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ola_map_view_flutter_method_channel.dart';

/// Plugin platform interface (method-channel default).
abstract class OlaMapViewFlutterPlatform extends PlatformInterface {
  /// Constructs a OlaMapViewFlutterPlatform.
  OlaMapViewFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static OlaMapViewFlutterPlatform _instance = MethodChannelOlaMapViewFlutter();

  /// The default instance of [OlaMapViewFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelOlaMapViewFlutter].
  static OlaMapViewFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OlaMapViewFlutterPlatform] when
  /// they register themselves.
  static set instance(OlaMapViewFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS version string. Used by the example plugin template.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
