import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/models.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

/// Roads APIs: snap-to-road, nearest roads, and speed limits.
class OlaMapsRoads {
  OlaMapsRoads({required String apiKey, OlaMapsHttp? http})
      : _http = http ?? OlaMapsHttp(apiKey: apiKey);

  final OlaMapsHttp _http;

  Future<SnapToRoadResult> snapToRoad({
    required List<Location> points,
    bool enhancePath = false,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/routing/v1/snapToRoad',
      query: {
        'points': OlaMapsHttp.encodePoints(points),
        'enhancePath': enhancePath,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    return SnapToRoadResult.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<NearestRoadResult>> nearestRoads({
    required List<Location> points,
    String mode = 'DRIVING',
    num? radius,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/routing/v1/nearestRoads',
      query: {
        'mode': mode,
        'points': OlaMapsHttp.encodePoints(points),
        if (radius != null) 'radius': radius,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    return ((map['results'] as List?) ?? const [])
        .map((item) =>
            NearestRoadResult.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<SpeedLimitsResult> speedLimits({
    required List<Location> points,
    String snapStrategy = 'snaptoroad',
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/routing/v1/speedLimits',
      query: {
        'points': OlaMapsHttp.encodePoints(points),
        'snapStrategy': snapStrategy,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    return SpeedLimitsResult.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
