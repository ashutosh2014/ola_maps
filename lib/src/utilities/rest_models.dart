import 'package:ola_maps/src/utilities/models.dart';

List<String> stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return value.split(',').map((item) => item.trim()).toList();
  }
  return const [];
}

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

class SnappedPoint {
  final Location location;
  final int? originalIndex;
  final String? snappedType;

  const SnappedPoint({
    required this.location,
    this.originalIndex,
    this.snappedType,
  });

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

class SnapToRoadResult {
  final String status;
  final List<SnappedPoint> snappedPoints;

  const SnapToRoadResult({
    required this.status,
    required this.snappedPoints,
  });

  factory SnapToRoadResult.fromJson(Map<String, dynamic> json) {
    return SnapToRoadResult(
      status: json['status']?.toString() ?? '',
      snappedPoints: ((json['snapped_points'] ?? json['snappedPoints']) as List? ?? const [])
          .map((item) => SnappedPoint.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class NearestRoadResult {
  final double lat;
  final double lng;
  final double? distance;
  final int? originalIndex;
  final String status;

  const NearestRoadResult({
    required this.lat,
    required this.lng,
    this.distance,
    this.originalIndex,
    required this.status,
  });

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

class SpeedLimitEntry {
  final int? originalIndex;
  final num? speedLimit;

  const SpeedLimitEntry({this.originalIndex, this.speedLimit});

  factory SpeedLimitEntry.fromJson(Map<String, dynamic> json) {
    return SpeedLimitEntry(
      originalIndex: (json['originalIndex'] as num?)?.toInt() ??
          (json['original_index'] as num?)?.toInt(),
      speedLimit: json['speedLimit'] as num? ?? json['speed_limit'] as num?,
    );
  }
}

class SpeedLimitsResult {
  final String status;
  final List<SnappedPoint> snappedPoints;
  final List<SpeedLimitEntry> speedLimits;

  const SpeedLimitsResult({
    required this.status,
    required this.snappedPoints,
    required this.speedLimits,
  });

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

class AddressValidationComponent {
  final String componentName;
  final String componentType;
  final String componentStatus;
  final String componentDetails;

  const AddressValidationComponent({
    required this.componentName,
    required this.componentType,
    required this.componentStatus,
    required this.componentDetails,
  });

  factory AddressValidationComponent.fromJson(Map<String, dynamic> json) {
    return AddressValidationComponent(
      componentName: json['componentName']?.toString() ?? '',
      componentType: json['componentType']?.toString() ?? '',
      componentStatus: json['componentStatus']?.toString() ?? '',
      componentDetails: json['componentDetails']?.toString() ?? '',
    );
  }
}

class AddressValidationResult {
  final bool validated;
  final String validatedAddress;
  final List<AddressValidationComponent> addressComponents;
  final String status;

  const AddressValidationResult({
    required this.validated,
    required this.validatedAddress,
    required this.addressComponents,
    required this.status,
  });

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

class PlacePhoto {
  final int? height;
  final int? width;
  final double? angle;
  final String photoReference;
  final String photoUri;

  const PlacePhoto({
    this.height,
    this.width,
    this.angle,
    required this.photoReference,
    required this.photoUri,
  });

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

class Geofence {
  final String geofenceId;
  final String? name;
  final String? type;
  final List<List<double>> coordinates;
  final double? radius;
  final String? status;
  final String? projectId;
  final String? message;

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

class GeofenceRequest {
  final String name;
  final String type;
  final List<List<double>> coordinates;
  final String projectId;
  final String status;
  final double? radius;

  const GeofenceRequest({
    required this.name,
    required this.type,
    required this.coordinates,
    required this.projectId,
    this.status = 'active',
    this.radius,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'coordinates': coordinates,
        'projectId': projectId,
        'status': status,
        if (radius != null) 'radius': radius,
      };
}

class GeofenceListResult {
  final int page;
  final int size;
  final int total;
  final List<Geofence> geofences;

  const GeofenceListResult({
    required this.page,
    required this.size,
    required this.total,
    required this.geofences,
  });

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

class GeofenceStatus {
  final String geofenceId;
  final bool isInside;
  final String message;

  const GeofenceStatus({
    required this.geofenceId,
    required this.isInside,
    required this.message,
  });

  factory GeofenceStatus.fromJson(Map<String, dynamic> json) {
    return GeofenceStatus(
      geofenceId: json['geofenceId']?.toString() ?? '',
      isInside: json['isInside'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

class ElevationResult {
  final double elevation;
  final Location location;

  const ElevationResult({
    required this.elevation,
    required this.location,
  });

  factory ElevationResult.fromJson(Map<String, dynamic> json) {
    return ElevationResult(
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0,
      location: Location.fromJson(
        Map<String, dynamic>.from(json['location'] as Map? ?? const {}),
      ),
    );
  }
}

class MapStyleInfo {
  final int? version;
  final String name;
  final String id;
  final String url;

  const MapStyleInfo({
    this.version,
    required this.name,
    required this.id,
    required this.url,
  });

  factory MapStyleInfo.fromJson(Map<String, dynamic> json) {
    return MapStyleInfo(
      version: (json['version'] as num?)?.toInt(),
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class StaticMapMarker {
  final double longitude;
  final double latitude;
  final String? iconColor;
  final double? scale;
  final String? offset;

  const StaticMapMarker({
    required this.longitude,
    required this.latitude,
    this.iconColor,
    this.scale,
    this.offset,
  });

  String toQuery() {
    final parts = <String>['$longitude,$latitude'];
    if (iconColor != null) parts.add(iconColor!);
    if (scale != null) parts.add('scale:$scale');
    if (offset != null) parts.add('offset:$offset');
    return parts.join('|');
  }
}

class StreetViewImageId {
  final String imageId;
  final Map<String, dynamic> raw;

  const StreetViewImageId({required this.imageId, this.raw = const {}});

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

class StreetViewMetadata {
  final String imageId;
  final double? latitude;
  final double? longitude;
  final double? bearing;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  const StreetViewMetadata({
    required this.imageId,
    this.latitude,
    this.longitude,
    this.bearing,
    this.imageUrl,
    this.raw = const {},
  });

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
