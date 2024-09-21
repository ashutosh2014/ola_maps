import 'dart:convert';

import 'package:ola_maps/src/utilities/enums.dart';
import 'package:ola_maps/src/utilities/exceptions.dart';
import 'package:ola_maps/src/utilities/models.dart';

import 'package:http/http.dart' as http;

class OlaMapsPlaces {
  String apiKey;

  final String placesApi = 'https://api.olamaps.io/places/v1';

  final String textsearch = '/textsearch';
  final String details = '/details';
  final String nearbysearch = '/nearbysearch';
  final String autocomplete = '/autocomplete';

  OlaMapsPlaces({required this.apiKey});

  /// Provides a list of places based on textual queries without needing actual location coordinates.
  ///
  /// Example queries:
  /// - "Cafes in Koramangala"
  /// - "Restaurants near Bangalore"
  ///
  /// - `input`: The search text for places.
  /// - `location`: The location from which to base the search.
  /// - `radius`: The search radius in meters (default: 5000).
  /// - `types`: A list of place types to filter results (e.g., restaurant, cafe).
  /// - `size`: The number of predictions to return (default: 5).
  Future<List<TextSearchPrediction>> getTextPredictions({
    required String input,
    required Location location,
    double radius = 5000,
    required List<String> types,
    int size = 5,
  }) async {
    var uri = Uri.parse(
        '$placesApi$textsearch?input=$input&location=${location.lat},${location.lng}&radius=${radius.toInt()}${types.isNotEmpty ? '&types=${types.join(',')}' : ''}&size=$size&api_key=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (parseStatus(jsonResponse['status']) == Status.ok) {
        return (jsonResponse['predictions'] as List)
            .map((result) => TextSearchPrediction.fromJson(result))
            .toList();
      } else if (parseStatus(jsonResponse['status']) == Status.zeroResults) {
        return [];
      }
    } else if (response.statusCode == 400) {
      final jsonResponse = json.decode(response.body);
      throw BadRequestException(jsonResponse['error_message'] ?? 'Bad request');
    } else if (response.statusCode == 500) {
      throw ServerException('Internal server error');
    }

    throw ApiException('Failed to load data');
  }

  /// Retrieves detailed information about a place specified by its ID.
  ///
  /// - `placeId`: The unique identifier for the place.
  ///
  /// Returns a [PlaceDetails] object containing the details of the specified place.
  Future<PlaceDetails> getPlaceDetails({
    required String placeId,
  }) async {
    var uri = Uri.parse('$placesApi$details?place_id=$placeId&api_key=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (parseStatus(jsonResponse['status']) == Status.ok) {
        return PlaceDetails.fromJson(jsonResponse['result']);
      } else if (parseStatus(jsonResponse['status']) == Status.zeroResults) {
        final jsonResponse = json.decode(response.body);
        throw BadRequestException(
            jsonResponse['error_message'] ?? 'Bad request');
      }
    } else if (response.statusCode == 400) {
      final jsonResponse = json.decode(response.body);
      throw BadRequestException(jsonResponse['error_message'] ?? 'Bad request');
    } else if (response.statusCode == 500) {
      throw ServerException('Internal server error');
    }

    throw ApiException('Failed to load data');
  }

  /// Provides nearby places of specific categories based on the provided location.
  ///
  /// - `location`: The latitude and longitude around which to search for places.
  /// - `layers`: A list of layers to search within (e.g., venue).
  /// - `types`: A list of place types to restrict results (e.g., restaurant).
  /// - `radius`: The distance in meters within which to return place results (default: 6000).
  /// - `strictBounds`: Whether to restrict results strictly within the radius (default: false).
  /// - `withCentroid`: Whether to include centroid information in results (default: false).
  /// - `limit`: Maximum number of results to return (default: 5, min: 5, max: 50).
  /// - `requestId`: Optional unique identifier for the request.
  /// - `correlationId`: Optional identifier for tracking transactions across multiple requests.
  ///
  /// Returns a list of [NearByPlaceDetails] objects.
  Future<List<NearByPlaceDetails>> getNearBySearchPlaces({
    required Location location,
    List<String> layers = const [],
    List<String> types = const [],
    int radius = 6000,
    bool strictBounds = false,
    bool withCentroid = false,
    int limit = 5,
    String? requestId,
    String? correlationId,
  }) async {
// Build the query parameters
    final queryParameters = {
      'location': location.toString(),
      if (layers.isNotEmpty) 'layers': layers,
      if (types.isNotEmpty) 'types': types,
      'radius': radius.toString(),
      'strictbounds': strictBounds.toString(),
      'withCentroid': withCentroid.toString(),
      'limit': limit.toString(),
    };

    // Construct the URI with query parameters
    var uri = Uri.parse(
        '$placesApi$nearbysearch?${Uri(queryParameters: queryParameters)}&api_key=$apiKey');

    // Set headers
    final headers = {
      if (requestId != null) 'X-Request-Id': requestId,
      if (correlationId != null) 'X-Correlation-Id': correlationId,
      'Accept': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    print(">>> ${response.body} >> ${response.statusCode}");
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (parseStatus(jsonResponse['status']) == Status.ok) {
        return (jsonResponse['predictions'] as List)
            .map((result) => NearByPlaceDetails.fromJson(result))
            .toList();
      } else if (parseStatus(jsonResponse['status']) == Status.zeroResults) {
        return [];
      }
    } else if (response.statusCode == 400) {
      final jsonResponse = json.decode(response.body);
      throw BadRequestException(jsonResponse['error_message'] ?? 'Bad request');
    } else if (response.statusCode == 500) {
      throw ServerException('Internal server error');
    }

    throw ApiException('Failed to load data');
  }

  /// Provides autocomplete suggestions for a given substring.
  ///
  /// This method is helpful when used with a debounce function to minimize the number of API calls.
  ///
  /// - `input`: The text string to search for suggestions.
  /// - `location`: Optional parameter for fetching more location-specific results, specified as latitude,longitude.
  /// - `radius`: Optional distance in meters within which to return place results.
  /// - `requestId`: Optional unique identifier for the request.
  /// - `correlationId`: Optional identifier for tracking transactions across multiple requests.
  ///
  /// Returns a list of [AutoCompleteResults] objects.
  Future<List<AutoCompleteResults>> getAutocompleteSuggestions({
    required String input,
    Location? location,
    int? radius,
    String? requestId,
    String? correlationId,
  }) async {
    // Build the query parameters
    final queryParameters = {
      if (location != null) 'location': location.toString(),
      'input': input,
      if (radius != null) 'radius': radius,
    };

    // Construct the URI with query parameters
    var uri = Uri.parse(
        '$placesApi$autocomplete${Uri(queryParameters: queryParameters)}&api_key=$apiKey');

    print("DSA>> ${uri.toString()}"); // Set headers
    final headers = {
      if (requestId != null) 'X-Request-Id': requestId,
      if (correlationId != null) 'X-Correlation-Id': correlationId,
      'Accept': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (parseStatus(jsonResponse['status']) == Status.ok) {
        return (jsonResponse['predictions'] as List)
            .map((result) => AutoCompleteResults.fromJson(result))
            .toList();
      } else if (parseStatus(jsonResponse['status']) == Status.zeroResults) {
        return [];
      }
    } else if (response.statusCode == 400) {
      final jsonResponse = json.decode(response.body);
      throw BadRequestException(jsonResponse['error_message'] ?? 'Bad request');
    } else if (response.statusCode == 500) {
      throw ServerException('Internal server error');
    }

    throw ApiException('Failed to load data');
  }
}
