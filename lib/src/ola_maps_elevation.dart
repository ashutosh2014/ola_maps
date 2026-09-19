import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/models.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

/// Point elevation lookups.
class OlaMapsElevation {
  /// Creates an elevation client. Pass [http] to share language defaults.
  OlaMapsElevation({required String apiKey, OlaMapsHttp? http})
      : _http = http ?? OlaMapsHttp(apiKey: apiKey);

  final OlaMapsHttp _http;

  /// Elevation at a single [location].
  Future<List<ElevationResult>> getElevation(
    Location location, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/elevation',
      query: {'location': '${location.lat},${location.lng}'},
      requestId: requestId,
      correlationId: correlationId,
    );
    return _parse(json);
  }

  /// Elevation at each of [locations].
  Future<List<ElevationResult>> getElevations(
    List<Location> locations, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'POST',
      '/places/v1/elevation',
      body: {
        'locations': [
          for (final location in locations) '${location.lat}, ${location.lng}',
        ],
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    return _parse(json);
  }

  List<ElevationResult> _parse(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    return ((map['results'] as List?) ?? const [])
        .map((item) =>
            ElevationResult.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
