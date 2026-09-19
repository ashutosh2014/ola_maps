/// Geographic coordinate used by the Ola Maps SDK.
class OlaLatLng {
  /// Degrees north of the equator.
  final double latitude;

  /// Degrees east of the prime meridian.
  final double longitude;

  /// Creates a coordinate from [latitude] and [longitude] in degrees.
  const OlaLatLng(this.latitude, this.longitude);

  /// Parses `{latitude, longitude}` from a platform channel payload.
  factory OlaLatLng.fromJson(Map<dynamic, dynamic> json) {
    return OlaLatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  /// Serializes this point for method channels and GeoJSON helpers.
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Value equality on [latitude] and [longitude].
  @override
  bool operator ==(Object other) {
    return other is OlaLatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  /// Combined hash of [latitude] and [longitude].
  @override
  int get hashCode => Object.hash(latitude, longitude);

  /// Debug string `OlaLatLng(lat, lng)`.
  @override
  String toString() => 'OlaLatLng($latitude, $longitude)';
}

/// Camera target plus zoom / bearing / tilt.
class OlaCameraPosition {
  /// Map center.
  final OlaLatLng target;

  /// Zoom level used by the native / web map.
  final double zoom;

  /// Clockwise rotation in degrees.
  final double bearing;

  /// Camera pitch in degrees.
  final double tilt;

  /// Creates a camera pose. [zoom] defaults to 15.
  const OlaCameraPosition({
    required this.target,
    this.zoom = 15,
    this.bearing = 0,
    this.tilt = 0,
  });

  /// Parses a camera payload from the platform view.
  factory OlaCameraPosition.fromJson(Map<dynamic, dynamic> json) {
    return OlaCameraPosition(
      target: OlaLatLng.fromJson(json),
      zoom: (json['zoom'] as num?)?.toDouble() ?? 0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
      tilt: (json['tilt'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Debug string with target, zoom, bearing, and tilt.
  @override
  String toString() =>
      'OlaCameraPosition(target: $target, zoom: $zoom, bearing: $bearing, tilt: $tilt)';
}

/// Line styles accepted by polylines and bezier curves.
class OlaLineType {
  /// Continuous stroke.
  static const solid = 'LINE_SOLID';

  /// Dashed stroke.
  static const dotted = 'LINE_DOTTED';
}

/// Default vector style used by Ola Maps (`OlaMapService` / Web SDK).
const String kOlaMapsDefaultTileUrl =
    'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json';

/// 3D tileset used by the [Ola Maps Web SDK](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup).
const String kOlaMapsDefaultThreeDTileset =
    'https://api.olamaps.io/tiles/vector/v1/3dtiles/tileset.json';

/// CDN URL for `olamaps-web-sdk` (UMD). The Flutter web plugin also loads this
/// automatically if the host page did not include the script tag.
const String kOlaMapsWebSdkUrl =
    'https://www.unpkg.com/olamaps-web-sdk@1.4.0/dist/olamaps-web-sdk.umd.js';
