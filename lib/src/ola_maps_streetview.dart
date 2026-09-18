import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

class OlaMapsStreetView {
  OlaMapsStreetView({required String apiKey, OlaMapsHttp? http})
      : _http = http ?? OlaMapsHttp(apiKey: apiKey);

  final OlaMapsHttp _http;

  /// Line-string coverage of street-view imagery inside a bounding box.
  Future<dynamic> coverage({
    required double xMin,
    required double yMin,
    required double xMax,
    required double yMax,
    String? requestId,
    String? correlationId,
  }) {
    return _http.getJson(
      '/sli/v1/streetview/coverage',
      query: {
        'xMin': xMin,
        'yMin': yMin,
        'xMax': xMax,
        'yMax': yMax,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
  }

  Future<StreetViewImageId> nearestImageId({
    required double latitude,
    required double longitude,
    int? radius,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/sli/v1/streetview/imageId',
      query: {
        'lat': latitude,
        'lon': longitude,
        if (radius != null) 'radius': radius,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    return StreetViewImageId.fromJson(_asMap(json));
  }

  Future<StreetViewMetadata> metadata(
    String imageId, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/sli/v1/streetview/metadata',
      query: {'imageId': imageId},
      requestId: requestId,
      correlationId: correlationId,
    );
    return StreetViewMetadata.fromJson(_asMap(json));
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map) return Map<String, dynamic>.from(json);
    if (json is List && json.isNotEmpty) {
      var first = json.first;
      while (first is List && first.isNotEmpty) {
        first = first.first;
      }
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return {'payload': json};
  }
}
