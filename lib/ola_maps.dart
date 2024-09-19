library ola_maps;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ola_maps/src/ola_maps_geoencoder.dart';

export 'src/utilities/models.dart';

class Olamaps {
  static Olamaps? _instance;
  late String _apiKey;

  final String placesApi = 'https://api.olamaps.io/places/v1';

  final String reverseGeocode = '/reverse-geocode';
  final String geocode = '/geocode';

  static Olamaps get instance => _instance ??= Olamaps();

  late OlamapsGeoencoder geoencoder;

  void initialize(String apiKey) {
    _apiKey = apiKey;
    geoencoder = OlamapsGeoencoder(apiKey: apiKey);
  }
}
