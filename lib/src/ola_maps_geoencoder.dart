import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/enums.dart';
import 'package:ola_maps/src/utilities/models.dart';

class OlamapsGeoencoder {
  final String apiKey;
  late final OlaMapsHttp _http;

  final String placesApi = 'https://api.olamaps.io/places/v1';
  final String reverseGeocode = '/reverse-geocode';
  final String geocode = '/geocode';

  OlamapsGeoencoder({required this.apiKey, OlaMapsHttp? httpClient})
      : _http = httpClient ?? OlaMapsHttp(apiKey: apiKey);

  /// Converts geographic coordinates into readable addresses or place names.
  Future<List<Address>> fetchAddresses(
    Location location, {
    String? language,
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/reverse-geocode',
      query: {
        'latlng': location.toString(),
        if (language != null) 'language': language,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    if (parseStatus(map['status']?.toString() ?? 'ok') == Status.zeroResults) {
      return [];
    }
    return ((map['results'] as List?) ?? const [])
        .map((result) => Address.fromJson(Map<String, dynamic>.from(result as Map)))
        .toList();
  }

  /// Retrieves geographic coordinates and detailed location information for a given address.
  Future<List<Address>> fetchLocation(
    String address, {
    String language = 'en',
    String? requestId,
    String? correlationId,
  }) async {
    final json = await _http.getJson(
      '/places/v1/geocode',
      query: {
        'address': address,
        'language': language,
      },
      requestId: requestId,
      correlationId: correlationId,
    );
    final map = Map<String, dynamic>.from(json as Map);
    if (parseStatus(map['status']?.toString() ?? 'ok') == Status.zeroResults) {
      return [];
    }
    return ((map['geocodingResults'] as List?) ?? const [])
        .map((result) => Address.fromJson(Map<String, dynamic>.from(result as Map)))
        .toList();
  }
}
