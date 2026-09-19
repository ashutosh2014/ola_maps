/// Flutter web registrar for the Ola Maps HtmlElementView.
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'package:ola_maps/src/web/ola_maps_web_host.dart';

/// Registers the Ola Maps [Web SDK](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup)
/// as a Flutter `HtmlElementView`.
class OlaMapViewFlutterWeb {
  /// Creates the web plugin registrar.
  OlaMapViewFlutterWeb();

  /// Registers the `ola_map_view_flutter` HtmlElementView factory.
  static void registerWith(Registrar registrar) {
    ui_web.platformViewRegistry.registerViewFactory(
      'ola_map_view_flutter',
      (int viewId) {
        final element = web.HTMLDivElement()
          ..id = 'ola-map-view-$viewId'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative';
        OlaMapsWebHost(viewId, element);
        return element;
      },
    );
  }
}
