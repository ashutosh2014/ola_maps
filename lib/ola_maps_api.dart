import 'package:ola_maps/ola_routing_service.dart';
import 'package:ola_maps/src/ola_maps_elevation.dart';
import 'package:ola_maps/src/ola_maps_geoencoder.dart';
import 'package:ola_maps/src/ola_maps_geofence.dart';
import 'package:ola_maps/src/ola_maps_places.dart';
import 'package:ola_maps/src/ola_maps_roads.dart';
import 'package:ola_maps/src/ola_maps_streetview.dart';
import 'package:ola_maps/src/ola_maps_tiles.dart';
import 'package:ola_maps/src/ola_maps_http.dart';
import 'package:ola_maps/src/utilities/ola_maps_language.dart';

export 'src/utilities/models.dart';
export 'src/utilities/rest_models.dart';
export 'src/utilities/exceptions.dart';
export 'src/utilities/enums.dart';
export 'src/widgets/widgets.dart';
export 'src/ola_maps_roads.dart';
export 'src/ola_maps_geofence.dart';
export 'src/ola_maps_elevation.dart';
export 'src/ola_maps_tiles.dart';
export 'src/ola_maps_streetview.dart';
export 'src/utilities/ola_maps_language.dart';

/// HTTP helpers for Ola Maps REST APIs (Places, Geocode, Roads, Geofencing,
/// Elevation, Tiles, Street View, Routing).
class Olamaps {
  static Olamaps? _instance;

  /// Shared REST client. Call [initialize] once before using the services.
  static Olamaps get instance => _instance ??= Olamaps();

  /// Forward and reverse geocoding.
  late OlamapsGeoencoder geoencoder;

  /// Autocomplete, place details, nearby, and photos.
  late OlaMapsPlaces places;

  /// Snap-to-road, nearest roads, and speed limits.
  late OlaMapsRoads roads;

  /// Geofence CRUD against an Ola Maps project.
  late OlaMapsGeofence geofence;

  /// Point elevation lookups.
  late OlaMapsElevation elevation;

  /// Static maps and style URLs.
  late OlaMapsTiles tiles;

  /// Street View metadata helpers.
  late OlaMapsStreetView streetView;

  /// Directions, distance matrix, and related routing calls.
  late OlaRoutingService routing;

  /// Default ISO 639-1 language applied to HTTP helpers.
  String language = OlaMapsLanguage.defaultCode;

  /// Configures every REST client with [apiKey] and optional [language].
  void initialize(
    String apiKey, {
    Object? language,
  }) {
    this.language = OlaMapsLanguage.codeOf(language);
    final http = OlaMapsHttp(
      apiKey: apiKey,
      defaultLanguage: this.language,
    );
    geoencoder = OlamapsGeoencoder(apiKey: apiKey, httpClient: http);
    places = OlaMapsPlaces(apiKey: apiKey, httpClient: http);
    roads = OlaMapsRoads(apiKey: apiKey, http: http);
    geofence = OlaMapsGeofence(apiKey: apiKey, http: http);
    elevation = OlaMapsElevation(apiKey: apiKey, http: http);
    tiles = OlaMapsTiles(apiKey: apiKey, http: http);
    streetView = OlaMapsStreetView(apiKey: apiKey, http: http);
    routing = OlaRoutingService(apiKey: apiKey, httpClient: http);
  }
}
