library ola_maps;

import 'package:ola_maps/src/ola_maps_geoencoder.dart';
import 'package:ola_maps/src/ola_maps_places.dart';

export 'src/utilities/models.dart';
export 'src/widgets/widgets.dart';

class Olamaps {
  static Olamaps? _instance;

  static Olamaps get instance => _instance ??= Olamaps();

  late OlamapsGeoencoder geoencoder;
  late OlaMapsPlaces places;

  void initialize(String apiKey) {
    geoencoder = OlamapsGeoencoder(apiKey: apiKey);
    places = OlaMapsPlaces(apiKey: apiKey);
  }
}
