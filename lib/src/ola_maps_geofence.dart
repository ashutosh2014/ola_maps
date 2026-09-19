import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/models.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

/// Geofence CRUD and point-in-fence checks.
class OlaMapsGeofence {
  /// Creates a geofence client. Pass [http] to share language defaults.
  OlaMapsGeofence({required String apiKey, OlaMapsHttp? http})
      : _http = http ?? OlaMapsHttp(apiKey: apiKey);

  final OlaMapsHttp _http;

  /// Creates a fence in the project from [request].
  Future<Geofence> create(
    GeofenceRequest request, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'POST',
      '/places/v1/geofence',
      body: request.toJson(),
      requestId: requestId,
      correlationId: correlationId,
    );
    return Geofence.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Replaces the fence identified by [id].
  Future<Geofence> update(
    String id,
    GeofenceRequest request, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'PUT',
      '/places/v1/geofence/${Uri.encodeComponent(id)}',
      body: request.toJson(),
      requestId: requestId,
      correlationId: correlationId,
    );
    return Geofence.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Fetches a fence by id.
  Future<Geofence> getById(
    String id, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/geofence/${Uri.encodeComponent(id)}',
      requestId: requestId,
      correlationId: correlationId,
    );
    return Geofence.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Deletes a fence by id.
  Future<Geofence> delete(
    String id, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'DELETE',
      '/places/v1/geofence/${Uri.encodeComponent(id)}',
      requestId: requestId,
      correlationId: correlationId,
    );
    return Geofence.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Paged list of fences for [projectId].
  Future<GeofenceListResult> list({
    required String projectId,
    int page = 1,
    int size = 10,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/geofences',
      query: {
        'projectId': projectId,
        'page': page,
        'size': size,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    return GeofenceListResult.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Whether [coordinates] is inside [geofenceId].
  Future<GeofenceStatus> status({
    required String geofenceId,
    required Location coordinates,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/geofence/status',
      query: {
        'geofenceId': geofenceId,
        'coordinates': '${coordinates.lat},${coordinates.lng}',
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    return GeofenceStatus.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
