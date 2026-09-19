import 'package:ola_maps/src/utilities/models.dart';

/// Coerces a JSON list or comma-separated string into `List<String>`.
List<String> stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return value.split(',').map((item) => item.trim()).toList();
  }
  return const [];
}

/// Flattens nested autocomplete prediction arrays.
List<dynamic> flattenPredictions(dynamic predictions) {
  if (predictions is Map) {
    return flattenPredictions(predictions.values.toList());
  }
  if (predictions is! List) return const [];
  if (predictions.isEmpty) return const [];
  if (predictions.first is List) {
    return predictions.expand((item) => item is List ? item : [item]).toList();
  }
  return predictions;
}

/// One GPS sample snapped onto the road network.
class SnappedPoint {
  /// Snapped coordinate.
  final Location location;

  /// Index in the original request list.
  final int? originalIndex;

  /// Snap classification from the Roads API.
  final String? snappedType;

  /// Creates a snapped point.
  const SnappedPoint({
    required this.location,
    this.originalIndex,
    this.snappedType,
  });

  /// Parses a snapped-point JSON object.
  factory SnappedPoint.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    return SnappedPoint(
      location: rawLocation is Map
          ? Location.fromJson(Map<String, dynamic>.from(rawLocation))
          : Location(lat: 0, lng: 0),
      originalIndex: (json['original_index'] as num?)?.toInt() ??
          (json['originalIndex'] as num?)?.toInt(),
      snappedType: json['snapped_type']?.toString() ?? json['snappedType']?.toString(),
    );
  }
}

/// Response from snap-to-road.
class SnapToRoadResult {
  /// API status string.
  final String status;

  /// Snapped path.
  final List<SnappedPoint> snappedPoints;

  /// Creates a snap-to-road result.
  const SnapToRoadResult({
    required this.status,
    required this.snappedPoints,
  });

  /// Parses snap-to-road JSON.
  factory SnapToRoadResult.fromJson(Map<String, dynamic> json) {
    return SnapToRoadResult(
      status: json['status']?.toString() ?? '',
      snappedPoints: ((json['snapped_points'] ?? json['snappedPoints']) as List? ?? const [])
          .map((item) => SnappedPoint.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Nearest road for a single query point.
class NearestRoadResult {
  /// Road latitude.
  final double lat;

  /// Road longitude.
  final double lng;

  /// Distance from the query point, in meters.
  final double? distance;

  /// Index in the original request list.
  final int? originalIndex;

  /// API status for this point.
  final String status;

  /// Creates a nearest-road row.
  const NearestRoadResult({
    required this.lat,
    required this.lng,
    this.distance,
    this.originalIndex,
    required this.status,
  });

  /// Parses a nearest-road JSON object.
  factory NearestRoadResult.fromJson(Map<String, dynamic> json) {
    return NearestRoadResult(
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble(),
      originalIndex: (json['originalIndex'] as num?)?.toInt() ??
          (json['original_index'] as num?)?.toInt(),
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Posted speed limit for one snapped point.
class SpeedLimitEntry {
  /// Index in the original request list.
  final int? originalIndex;

  /// Speed limit value from the API.
  final num? speedLimit;

  /// Creates a speed-limit row.
  const SpeedLimitEntry({this.originalIndex, this.speedLimit});

  /// Parses a speed-limit JSON object.
  factory SpeedLimitEntry.fromJson(Map<String, dynamic> json) {
    return SpeedLimitEntry(
      originalIndex: (json['originalIndex'] as num?)?.toInt() ??
          (json['original_index'] as num?)?.toInt(),
      speedLimit: json['speedLimit'] as num? ?? json['speed_limit'] as num?,
    );
  }
}

/// Response from the speed-limits API.
class SpeedLimitsResult {
  /// API status string.
  final String status;

  /// Snapped path used for the lookup.
  final List<SnappedPoint> snappedPoints;

  /// Speed limits aligned with [snappedPoints].
  final List<SpeedLimitEntry> speedLimits;

  /// Creates a speed-limits result.
  const SpeedLimitsResult({
    required this.status,
    required this.snappedPoints,
    required this.speedLimits,
  });

  /// Parses speed-limits JSON.
  factory SpeedLimitsResult.fromJson(Map<String, dynamic> json) {
    return SpeedLimitsResult(
      status: json['status']?.toString() ?? '',
      snappedPoints: ((json['snappedPoints'] ?? json['snapped_points']) as List? ?? const [])
          .map((item) => SnappedPoint.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      speedLimits: (json['speedLimits'] as List? ?? const [])
          .map((item) => SpeedLimitEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// One component from address validation.
class AddressValidationComponent {
  /// Component display name.
  final String componentName;

  /// Component type.
  final String componentType;

  /// Validation status for this part.
  final String componentStatus;

  /// Extra detail from the API.
  final String componentDetails;

  /// Creates a validation component.
  const AddressValidationComponent({
    required this.componentName,
    required this.componentType,
    required this.componentStatus,
    required this.componentDetails,
  });

  /// Parses a validation-component JSON object.
  factory AddressValidationComponent.fromJson(Map<String, dynamic> json) {
    return AddressValidationComponent(
      componentName: json['componentName']?.toString() ?? '',
      componentType: json['componentType']?.toString() ?? '',
      componentStatus: json['componentStatus']?.toString() ?? '',
      componentDetails: json['componentDetails']?.toString() ?? '',
    );
  }
}

/// Result of an address-validation call.
class AddressValidationResult {
  /// Whether the address was accepted.
  final bool validated;

  /// Normalized address string.
  final String validatedAddress;

  /// Validated components.
  final List<AddressValidationComponent> addressComponents;

  /// API status string.
  final String status;

  /// Creates a validation result.
  const AddressValidationResult({
    required this.validated,
    required this.validatedAddress,
    required this.addressComponents,
    required this.status,
  });

  /// Parses address-validation JSON.
  factory AddressValidationResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map
        ? Map<String, dynamic>.from(json['result'] as Map)
        : json;
    final rawComponents = result['address_components'] as List? ?? const [];
    final components = <AddressValidationComponent>[];
    for (final item in rawComponents) {
      if (item is! Map) continue;
      for (final value in item.values) {
        if (value is Map) {
          components.add(
            AddressValidationComponent.fromJson(Map<String, dynamic>.from(value)),
          );
        }
      }
    }
    return AddressValidationResult(
      validated: result['validated'] == true,
      validatedAddress: result['validated_address']?.toString() ?? '',
      addressComponents: components,
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Photo metadata from Places.
class PlacePhoto {
  /// Pixel height.
  final int? height;

  /// Pixel width.
  final int? width;

  /// Camera angle, if provided.
  final double? angle;

  /// Photo reference token.
  final String photoReference;

  /// Direct photo URI.
  final String photoUri;

  /// Creates photo metadata.
  const PlacePhoto({
    this.height,
    this.width,
    this.angle,
    required this.photoReference,
    required this.photoUri,
  });

  /// Parses a photo JSON object.
  factory PlacePhoto.fromJson(Map<String, dynamic> json) {
    return PlacePhoto(
      height: (json['height'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      angle: (json['angle'] as num?)?.toDouble(),
      photoReference: json['photo_reference']?.toString() ?? '',
      photoUri: json['photoUri']?.toString() ?? json['photo_uri']?.toString() ?? '',
    );
  }
}

/// Stored geofence from the Places Geofence API.
class Geofence {
  /// Server-assigned fence id.
  final String geofenceId;

  /// Display name.
  final String? name;

  /// Geometry type (`polygon`, `circle`, …).
  final String? type;

  /// Ring or circle-center coordinates.
  final List<List<double>> coordinates;

  /// Circle radius in meters, when [type] is a circle.
  final double? radius;

  /// Lifecycle status (`active`, …).
  final String? status;

  /// Owning project id.
  final String? projectId;

  /// Optional server message.
  final String? message;

  /// Creates a geofence record.
  const Geofence({
    required this.geofenceId,
    this.name,
    this.type,
    this.coordinates = const [],
    this.radius,
    this.status,
    this.projectId,
    this.message,
  });

  /// Parses a geofence JSON object (including `schema` envelopes).
  factory Geofence.fromJson(Map<String, dynamic> json) {
    final raw = json['schema'] is Map
        ? Map<String, dynamic>.from(json['schema'] as Map)
        : json;
    final coords = <List<double>>[];
    for (final pair in raw['coordinates'] as List? ?? const []) {
      if (pair is List && pair.length >= 2) {
        coords.add([
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        ]);
      }
    }
    return Geofence(
      geofenceId: raw['geofenceId']?.toString() ?? json['geofenceId']?.toString() ?? '',
      name: raw['name']?.toString(),
      type: raw['type']?.toString(),
      coordinates: coords,
      radius: (raw['radius'] as num?)?.toDouble(),
      status: raw['status']?.toString() ?? json['status']?.toString(),
      projectId: raw['projectId']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

/// Payload for create/update geofence calls.
class GeofenceRequest {
  /// Display name.
  final String name;

  /// Geometry type (`polygon`, `circle`, …).
  final String type;

  /// Ring or circle-center coordinates.
  final List<List<double>> coordinates;

  /// Owning project id.
  final String projectId;

  /// Lifecycle status. Defaults to `active`.
  final String status;

  /// Circle radius in meters, when [type] is a circle.
  final double? radius;

  /// Creates a create/update request.
  const GeofenceRequest({
    required this.name,
    required this.type,
    required this.coordinates,
    required this.projectId,
    this.status = 'active',
    this.radius,
  });

  /// Serializes the request body.
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'coordinates': coordinates,
        'projectId': projectId,
        'status': status,
        if (radius != null) 'radius': radius,
      };
}

/// Paged list of [Geofence] records.
class GeofenceListResult {
  /// Current page index.
  final int page;

  /// Page size.
  final int size;

  /// Total matching fences.
  final int total;

  /// Fences on this page.
  final List<Geofence> geofences;

  /// Creates a paged result.
  const GeofenceListResult({
    required this.page,
    required this.size,
    required this.total,
    required this.geofences,
  });

  /// Parses a paged geofence list.
  factory GeofenceListResult.fromJson(Map<String, dynamic> json) {
    return GeofenceListResult(
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      geofences: (json['geofences'] as List? ?? const [])
          .map((item) => Geofence.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Point-in-fence check result.
class GeofenceStatus {
  /// Fence that was tested.
  final String geofenceId;

  /// Whether the query point is inside.
  final bool isInside;

  /// Server message.
  final String message;

  /// Creates a status result.
  const GeofenceStatus({
    required this.geofenceId,
    required this.isInside,
    required this.message,
  });

  /// Parses a status JSON object.
  factory GeofenceStatus.fromJson(Map<String, dynamic> json) {
    return GeofenceStatus(
      geofenceId: json['geofenceId']?.toString() ?? '',
      isInside: json['isInside'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Elevation at a coordinate.
class ElevationResult {
  /// Elevation in meters.
  final double elevation;

  /// Query coordinate.
  final Location location;

  /// Creates an elevation row.
  const ElevationResult({
    required this.elevation,
    required this.location,
  });

  /// Parses an elevation JSON object.
  factory ElevationResult.fromJson(Map<String, dynamic> json) {
    return ElevationResult(
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0,
      location: Location.fromJson(
        Map<String, dynamic>.from(json['location'] as Map? ?? const {}),
      ),
    );
  }
}

/// Published vector style from the Tiles API.
class MapStyleInfo {
  /// Style version, if provided.
  final int? version;

  /// Style display name.
  final String name;

  /// Style id.
  final String id;

  /// Style JSON URL.
  final String url;

  /// Creates style metadata.
  const MapStyleInfo({
    this.version,
    required this.name,
    required this.id,
    required this.url,
  });

  /// Parses a style-info JSON object.
  factory MapStyleInfo.fromJson(Map<String, dynamic> json) {
    return MapStyleInfo(
      version: (json['version'] as num?)?.toInt(),
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

/// Marker overlay for a static map image.
class StaticMapMarker {
  /// Marker longitude.
  final double longitude;

  /// Marker latitude.
  final double latitude;

  /// Optional pin color.
  final String? iconColor;

  /// Optional scale factor.
  final double? scale;

  /// Optional pixel offset.
  final String? offset;

  /// Creates a static-map marker.
  const StaticMapMarker({
    required this.longitude,
    required this.latitude,
    this.iconColor,
    this.scale,
    this.offset,
  });

  /// Encodes this marker as a `marker` query value.
  String toQuery() {
    final parts = <String>['$longitude,$latitude'];
    if (iconColor != null) parts.add(iconColor!);
    if (scale != null) parts.add('scale:$scale');
    if (offset != null) parts.add('offset:$offset');
    return parts.join('|');
  }
}

/// Nearest Street View panorama id.
class StreetViewImageId {
  /// Panorama id.
  final String imageId;

  /// Unparsed API payload.
  final Map<String, dynamic> raw;

  /// Creates an image-id result.
  const StreetViewImageId({required this.imageId, this.raw = const {}});

  /// Parses an image-id JSON object.
  factory StreetViewImageId.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : json;
    return StreetViewImageId(
      imageId: (payload['imageId'] ??
              payload['image_id'] ??
              json['imageId'] ??
              json['image_id'] ??
              '')
          .toString(),
      raw: json,
    );
  }
}

/// Metadata for a Street View panorama.
class StreetViewMetadata {
  /// Panorama id.
  final String imageId;

  /// Capture latitude.
  final double? latitude;

  /// Capture longitude.
  final double? longitude;

  /// Camera bearing in degrees.
  final double? bearing;

  /// Preview image URL, if provided.
  final String? imageUrl;

  /// Unparsed API payload.
  final Map<String, dynamic> raw;

  /// Creates panorama metadata.
  const StreetViewMetadata({
    required this.imageId,
    this.latitude,
    this.longitude,
    this.bearing,
    this.imageUrl,
    this.raw = const {},
  });

  /// Parses Street View metadata JSON.
  factory StreetViewMetadata.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : json;
    return StreetViewMetadata(
      imageId: (payload['imageId'] ?? payload['image_id'] ?? '').toString(),
      latitude: (payload['lat'] as num?)?.toDouble() ??
          (payload['latitude'] as num?)?.toDouble(),
      longitude: (payload['lon'] as num?)?.toDouble() ??
          (payload['lng'] as num?)?.toDouble() ??
          (payload['longitude'] as num?)?.toDouble(),
      bearing: (payload['bearing'] as num?)?.toDouble() ??
          (payload['bearingAngle'] as num?)?.toDouble(),
      imageUrl: payload['imageUrl']?.toString() ?? payload['image_url']?.toString(),
      raw: json,
    );
  }
}
