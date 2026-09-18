import 'dart:typed_data';

import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/ola_maps_language.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

class OlaMapsTiles {
  static const lightStandard = OlaMapsLanguage.lightStandardStyle;
  static const darkStandard = OlaMapsLanguage.darkStandardStyle;

  OlaMapsTiles({required String apiKey, OlaMapsHttp? http})
      : _http = http ?? OlaMapsHttp(apiKey: apiKey);

  final OlaMapsHttp _http;

  /// Vector style JSON URL for Dynamic Maps. Non-English languages use
  /// `default-light-standard-{code}` (e.g. `default-light-standard-ml`).
  String styleUrl({
    Object? language,
    bool dark = false,
    String? baseStyle,
  }) {
    return OlaMapsLanguage.dynamicMapStyleUrl(
      language: language ?? _http.defaultLanguage,
      dark: dark,
      baseStyle: baseStyle,
    );
  }

  String styleName({
    Object? language,
    bool dark = false,
    String? baseStyle,
  }) {
    return OlaMapsLanguage.mapStyleName(
      language: language ?? _http.defaultLanguage,
      dark: dark,
      baseStyle: baseStyle,
    );
  }

  Future<List<MapStyleInfo>> listStyles({
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/tiles/vector/v1/styles.json',
      requestId: requestId,
      correlationId: correlationId,
    );
    final list = json is List ? json : const [];
    return list
        .map((item) =>
            MapStyleInfo.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Uint8List> staticMapByCenter({
    required double longitude,
    required double latitude,
    required double zoom,
    int width = 800,
    int height = 600,
    String format = 'png',
    String styleName = lightStandard,
    Object? language,
    bool dark = false,
    List<StaticMapMarker> markers = const [],
    String? path,
    String? requestId,
    String? correlationId,
  }) {
    final style = this.styleName(
      language: language,
      dark: dark,
      baseStyle: styleName,
    );
    return _http.getBytes(
      '/tiles/v1/styles/$style/static/$longitude,$latitude,$zoom/${width}x$height.$format',
      query: _http.withLanguage(
        _overlayQuery(markers, path) ?? <String, dynamic>{},
        language: language,
      ),
      requestId: requestId,
      correlationId: correlationId,
    );
  }

  Future<Uint8List> staticMapByBounds({
    required double minLongitude,
    required double minLatitude,
    required double maxLongitude,
    required double maxLatitude,
    int width = 800,
    int height = 600,
    String format = 'png',
    String styleName = lightStandard,
    Object? language,
    bool dark = false,
    List<StaticMapMarker> markers = const [],
    String? path,
    String? requestId,
    String? correlationId,
  }) {
    final style = this.styleName(
      language: language,
      dark: dark,
      baseStyle: styleName,
    );
    return _http.getBytes(
      '/tiles/v1/styles/$style/static/$minLongitude,$minLatitude,$maxLongitude,$maxLatitude/${width}x$height.$format',
      query: _http.withLanguage(
        _overlayQuery(markers, path) ?? <String, dynamic>{},
        language: language,
      ),
      requestId: requestId,
      correlationId: correlationId,
    );
  }

  Future<Uint8List> staticMapByPath({
    required String path,
    int width = 800,
    int height = 600,
    String format = 'png',
    String styleName = lightStandard,
    Object? language,
    bool dark = false,
    List<StaticMapMarker> markers = const [],
    String? requestId,
    String? correlationId,
  }) {
    final style = this.styleName(
      language: language,
      dark: dark,
      baseStyle: styleName,
    );
    return _http.getBytes(
      '/tiles/v1/styles/$style/static/auto/${width}x$height.$format',
      query: _http.withLanguage({
        'path': path,
        ...?_overlayQuery(markers, null),
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
  }

  Future<Map<String, dynamic>> tileset3d({
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/tiles/vector/v1/3dtiles/tileset.json',
      requestId: requestId,
      correlationId: correlationId,
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Map<String, dynamic>? _overlayQuery(
    List<StaticMapMarker> markers,
    String? path,
  ) {
    if (markers.isEmpty && (path == null || path.isEmpty)) return null;
    return {
      if (markers.isNotEmpty)
        'marker': markers.map((marker) => marker.toQuery()).toList(),
      if (path != null && path.isNotEmpty) 'path': path,
    };
  }
}
