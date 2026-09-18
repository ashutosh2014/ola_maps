import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/models.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

class OlaMapsGeofence {
  OlaMapsGeofence({required String apiKey, OlaMapsHttp? http})
      : _http = http ?? OlaMapsHttp(apiKey: apiKey);

  final OlaMapsHttp _http;

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
