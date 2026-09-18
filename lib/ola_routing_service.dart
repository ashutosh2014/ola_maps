import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with Ola Maps Routing API
class OlaRoutingService {
  final String apiKey;

  OlaRoutingService({required this.apiKey});

  /// Fetch directions from origin to destination
  /// Returns list of LatLng points representing the route
  Future<List<Map<String, double>>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      'https://api.olamaps.io/routing/v1/directions'
      '?origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
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
}
