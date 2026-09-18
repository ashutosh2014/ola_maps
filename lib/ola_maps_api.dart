import 'package:ola_maps/ola_routing_service.dart';
import 'package:ola_maps/src/ola_maps_elevation.dart';
import 'package:ola_maps/src/ola_maps_geoencoder.dart';
import 'package:ola_maps/src/ola_maps_geofence.dart';
import 'package:ola_maps/src/ola_maps_places.dart';
import 'package:ola_maps/src/ola_maps_roads.dart';
import 'package:ola_maps/src/ola_maps_streetview.dart';
import 'package:ola_maps/src/ola_maps_tiles.dart';

export 'src/utilities/models.dart';
export 'src/utilities/rest_models.dart';
export 'src/utilities/exceptions.dart';
export 'src/widgets/widgets.dart';
export 'src/ola_maps_roads.dart';
export 'src/ola_maps_geofence.dart';
export 'src/ola_maps_elevation.dart';
export 'src/ola_maps_tiles.dart';
export 'src/ola_maps_streetview.dart';

/// HTTP helpers for Ola Maps REST APIs (Places, Geocode, Roads, Geofencing,
/// Elevation, Tiles, Street View, Routing).
class Olamaps {
  static Olamaps? _instance;

  static Olamaps get instance => _instance ??= Olamaps();

  late OlamapsGeoencoder geoencoder;
  late OlaMapsPlaces places;
  late OlaMapsRoads roads;
  late OlaMapsGeofence geofence;
  late OlaMapsElevation elevation;
  late OlaMapsTiles tiles;
  late OlaMapsStreetView streetView;
  late OlaRoutingService routing;

  void initialize(String apiKey) {
    geoencoder = OlamapsGeoencoder(apiKey: apiKey);
    places = OlaMapsPlaces(apiKey: apiKey);
    roads = OlaMapsRoads(apiKey: apiKey);
    geofence = OlaMapsGeofence(apiKey: apiKey);
    elevation = OlaMapsElevation(apiKey: apiKey);
    tiles = OlaMapsTiles(apiKey: apiKey);
    streetView = OlaMapsStreetView(apiKey: apiKey);
    routing = OlaRoutingService(apiKey: apiKey);
  }
}
