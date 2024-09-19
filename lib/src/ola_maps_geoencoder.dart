import 'dart:convert';

import 'package:ola_maps/src/utilities/enums.dart';
import 'package:ola_maps/src/utilities/exceptions.dart';
import 'package:ola_maps/src/utilities/models.dart';

import 'package:http/http.dart' as http;

class OlamapsGeoencoder {
  String apiKey;

  final String placesApi = 'https://api.olamaps.io/places/v1';

  final String reverseGeocode = '/reverse-geocode';
  final String geocode = '/geocode';

  OlamapsGeoencoder({required this.apiKey});

  Future<List<Address>> fetchAddresses(Location location) async {
    var uri = Uri.parse(
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

  Future<List<Address>> fetchLocation(String address) async {
    var uri = Uri.parse('$placesApi$geocode?address=$geocode&api_key=$apiKey');
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
