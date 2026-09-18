import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/models.dart';

/// Service for interacting with Ola Maps Routing API
class OlaRoutingService {
  final String apiKey;
  late final OlaMapsHttp _http;

  OlaRoutingService({required this.apiKey, OlaMapsHttp? httpClient})
      : _http = httpClient ?? OlaMapsHttp(apiKey: apiKey);

  /// Fetch directions from origin to destination.
  Future<List<Map<String, double>>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving',
    bool alternatives = false,
    bool steps = false,
    Object? language,
  }) async {
    final lang = _http.resolvedLanguage(language);
    final url = Uri.parse(
      'https://api.olamaps.io/routing/v1/directions'
      '?origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&mode=$mode'
      '&alternatives=$alternatives'
      '&steps=$steps'
      '&overview=full'
      '${lang != null ? '&language=$lang' : ''}'
      '&api_key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'X-Request-Id': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract route coordinates from response
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['overview_polyline'];
          
          if (geometry != null) {
            // Decode polyline to get coordinates
            return _decodePolyline(geometry);
          }
        }
        
        // Fallback: return direct line if no geometry
        return [
          {'lat': originLat, 'lng': originLng},
          {'lat': destLat, 'lng': destLng},
        ];
      } else {
        print('Routing API error: ${response.statusCode} - ${response.body}');
        // Return direct line on error
        return [
          {'lat': originLat, 'lng': originLng},
          {'lat': destLat, 'lng': destLng},
        ];
      }
    } catch (e) {
      print('Error fetching directions: $e');
      // Return direct line on error
      return [
        {'lat': originLat, 'lng': originLng},
        {'lat': destLat, 'lng': destLng},
      ];
    }
  }

  /// Decode polyline string to list of coordinates
  List<Map<String, double>> _decodePolyline(String encoded) {
    List<Map<String, double>> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add({
        'lat': lat / 1e5,
        'lng': lng / 1e5,
      });
    }

    return points;
  }

  Future<Map<String, dynamic>> getDirectionsRaw({
    required Location origin,
    required Location destination,
    String mode = 'driving',
    bool alternatives = false,
    bool steps = false,
    String overview = 'full',
    bool basic = false,
    Object? language,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'POST',
      basic ? '/routing/v1/directions/basic' : '/routing/v1/directions',
      query: _http.withLanguage({
        'origin': origin.toString(),
        'destination': destination.toString(),
        'mode': mode,
        'alternatives': alternatives,
        'steps': steps,
        'overview': overview,
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> getDistanceMatrix({
    required List<Location> origins,
    required List<Location> destinations,
    String mode = 'driving',
    bool basic = false,
    Object? language,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      basic
          ? '/routing/v1/distanceMatrix/basic'
          : '/routing/v1/distanceMatrix',
      query: _http.withLanguage({
        'origins': OlaMapsHttp.encodePoints(origins),
        'destinations': OlaMapsHttp.encodePoints(destinations),
        'mode': mode,
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> optimizeRoute(
    Map<String, dynamic> body, {
    Object? language,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'POST',
      '/routing/v1/routeOptimizer',
      body: _http.withLanguageBody(body, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> planFleet(
    Map<String, dynamic> body, {
    Object? language,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.sendJson(
      'POST',
      '/routing/v1/fleetPlanner',
      body: _http.withLanguageBody(body, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    return Map<String, dynamic>.from(json as Map);
  }
}
