library ola_maps;

import 'package:ola_maps/src/ola_maps_geoencoder.dart';

export 'src/utilities/models.dart';

class Olamaps {
  static Olamaps? _instance;

  static Olamaps get instance => _instance ??= Olamaps();

  late OlamapsGeoencoder geoencoder;

  void initialize(String apiKey) {
    geoencoder = OlamapsGeoencoder(apiKey: apiKey);
  }
}
