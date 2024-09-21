import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ola_maps/src/utilities/enums.dart';
import 'package:ola_maps/src/utilities/exceptions.dart';
import 'package:ola_maps/src/utilities/models.dart';

class OlamapsGeoencoder {
  final String apiKey;

  final String placesApi = 'https://api.olamaps.io/places/v1';
  final String reverseGeocode = '/reverse-geocode';
  final String geocode = '/geocode';

  OlamapsGeoencoder({required this.apiKey});

  /// Converts geographic coordinates into readable addresses or place names.
  ///
  /// Takes a [Location] object representing the latitude and longitude.
  /// Returns a list of [Address] objects if successful, or throws an exception
  /// in case of an error.
  Future<List<Address>> fetchAddresses(Location location) async {
    final uri = Uri.parse(
        '$placesApi$reverseGeocode?latlng=${location.lat},${location.lng}&api_key=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (parseStatus(jsonResponse['status']) == Status.ok) {
        return (jsonResponse['results'] as List)
            .map((result) => Address.fromJson(result))
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

  /// Retrieves geographic coordinates and detailed location information for a given address.
  ///
  /// Takes an [address] string as input, which should represent a readable address.
  /// Returns a list of [Address] objects containing the results, or throws an exception
  /// if the request fails or returns an error.
  Future<List<Address>> fetchLocation(String address) async {
    final uri = Uri.parse(
        '$placesApi$geocode?address=${Uri.encodeComponent(address)}&api_key=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (parseStatus(jsonResponse['status']) == Status.ok) {
        return (jsonResponse['geocodingResults'] as List)
            .map((result) => Address.fromJson(result))
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
