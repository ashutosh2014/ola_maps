import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/enums.dart';
import 'package:ola_maps/src/utilities/exceptions.dart';
import 'package:ola_maps/src/utilities/models.dart';
import 'package:ola_maps/src/utilities/rest_models.dart';

class OlaMapsPlaces {
  String apiKey;
  late final OlaMapsHttp _http;

  final String placesApi = 'https://api.olamaps.io/places/v1';

  final String textsearch = '/textsearch';
  final String details = '/details';
  final String nearbysearch = '/nearbysearch';
  final String autocomplete = '/autocomplete';

  OlaMapsPlaces({required this.apiKey, OlaMapsHttp? httpClient})
      : _http = httpClient ?? OlaMapsHttp(apiKey: apiKey);

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
    Location? location,
    double? radius,
    List<String> types = const [],
    int size = 5,
    Object? language,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/textsearch',
      query: _http.withLanguage({
        'input': input,
        if (location != null) 'location': location.toString(),
        if (radius != null) 'radius': radius,
        if (types.isNotEmpty) 'types': types.join(','),
        'size': size,
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    if (parseStatus(map['status']?.toString() ?? 'ok') == Status.zeroResults) {
      return [];
    }
    return flattenPredictions(map['predictions'])
        .whereType<Map>()
        .map((item) => TextSearchPrediction.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Retrieves detailed information about a place specified by its ID.
  ///
  /// - `placeId`: The unique identifier for the place.
  ///
  /// Returns a [PlaceDetails] object containing the details of the specified place.
  Future<PlaceDetails> getPlaceDetails({
    required String placeId,
    Object? language,
    bool advanced = false,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      advanced ? '/places/v1/details/advanced' : '/places/v1/details',
      query: _http.withLanguage({
        'place_id': placeId,
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    final result = map['result'];
    if (result is Map) {
      return PlaceDetails.fromJson(Map<String, dynamic>.from(result));
    }
    throw ApiException(map['error_message']?.toString() ?? 'Place not found');
  }

  Future<PlaceDetails> getAdvancedPlaceDetails({
    required String placeId,
    Object? language,
    String? requestId,
    String? correlationId,
  }) {
    return getPlaceDetails(
      placeId: placeId,
      language: language,
      advanced: true,
      requestId: requestId,
      correlationId: correlationId,
    );
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
    Object? language,
    String rankBy = 'popular',
    bool advanced = false,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      advanced
          ? '/places/v1/nearbysearch/advanced'
          : '/places/v1/nearbysearch',
      query: _http.withLanguage({
        'location': location.toString(),
        if (layers.isNotEmpty) 'layers': layers.join(','),
        if (types.isNotEmpty) 'types': types.join(','),
        'radius': radius,
        'strictbounds': strictBounds,
        'withCentroid': withCentroid,
        'limit': limit,
        'rankBy': rankBy,
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    if (parseStatus(map['status']?.toString() ?? 'ok') == Status.zeroResults) {
      return [];
    }
    return flattenPredictions(map['predictions'])
        .whereType<Map>()
        .map((item) => NearByPlaceDetails.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<NearByPlaceDetails>> getAdvancedNearbySearchPlaces({
    required Location location,
    List<String> types = const [],
    int radius = 6000,
    bool withCentroid = false,
    int limit = 5,
    Object? language,
    String rankBy = 'popular',
    String? requestId,
    String? correlationId,
  }) {
    return getNearBySearchPlaces(
      location: location,
      types: types,
      radius: radius,
      withCentroid: withCentroid,
      limit: limit,
      language: language,
      rankBy: rankBy,
      advanced: true,
      requestId: requestId,
      correlationId: correlationId,
    );
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
    bool? strictBounds,
    Object? language,
    List<String> types = const [],
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/autocomplete',
      query: _http.withLanguage({
        'input': input,
        if (location != null) 'location': location.toString(),
        if (radius != null) 'radius': radius,
        if (strictBounds != null) 'strictbounds': strictBounds,
        if (types.isNotEmpty) 'types': types.join(','),
      }, language: language),
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    if (parseStatus(map['status']?.toString() ?? 'ok') == Status.zeroResults) {
      return [];
    }
    return flattenPredictions(map['predictions'])
        .whereType<Map>()
        .map((item) =>
            AutoCompleteResults.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AddressValidationResult> validateAddress(
    String address, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/addressvalidation',
      query: {'address': address},
      requestId: requestId,
      correlationId: correlationId,
    );
    return AddressValidationResult.fromJson(
      Map<String, dynamic>.from(json as Map),
    );
  }

  Future<List<PlacePhoto>> getPhoto(
    String photoReference, {
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/photo',
      query: {'photo_reference': photoReference},
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    return ((map['photos'] as List?) ?? const [])
        .map((item) => PlacePhoto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
