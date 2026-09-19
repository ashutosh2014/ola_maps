import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ola_maps/src/map/ola_map_auth.dart';
import 'package:ola_maps/src/map/ola_map_channels.dart'
    if (dart.library.html) 'package:ola_maps/src/map/ola_map_channels_web.dart'
    if (dart.library.js_interop) 'package:ola_maps/src/map/ola_map_channels_web.dart';
import 'package:ola_maps/src/map/ola_map_models.dart';

/// Overlay and camera API for a single [OlaMapView] instance.
class OlaMapController {
  /// Platform-view identifier for this map.
  final int id;
  StreamSubscription? _cameraSub;
  final Completer<void> _ready = Completer<void>();
  Object? _loadError;

  /// Fires after the camera stops moving.
  void Function(OlaLatLng position)? onCameraIdle;

  /// Fires when the user taps the map (not a marker).
  void Function(OlaLatLng position)? onMapClick;

  /// Fires on a long-press on the map.
  void Function(OlaLatLng position)? onMapLongClick;

  /// Fires when a marker is tapped. The argument is the marker id.
  void Function(String markerId)? onMarkerClick;

  /// Fires when the native map reports a load or style error.
  void Function(String error)? onMapError;

  OlaMapController._(this.id) {
    olaMapListen(id, _onNativeCall);
    _cameraSub = olaMapCameraStream(id)?.listen((event) {
      final point = _latLng(event);
      if (point != null) onCameraIdle?.call(point);
    });
  }

  static final Map<int, OlaMapController> _controllers = {};

  /// Platform-view factory. Prefer [OlaMapView.onControllerReady] in apps.
  factory OlaMapController.forPlatformView(int id) {
    return _controllers.putIfAbsent(id, () => OlaMapController._(id));
  }

  Future<dynamic> _invoke(String method, [dynamic arguments]) {
    return olaMapInvoke(id, method, arguments);
  }

  Future<void> _run(String method, [Map<String, dynamic>? args]) async {
    try {
      await _invoke(method, args);
    } catch (e) {
      debugPrint('Error $method: $e');
    }
  }

  Future<String?> _runForId(String method, Map<String, dynamic> args) async {
    try {
      return await _invoke(method, args) as String?;
    } catch (e) {
      debugPrint('Error $method: $e');
      return null;
    }
  }

  static String _nextOverlayId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static OlaLatLng? _latLng(dynamic value) {
    final map = _asMap(value);
    return map == null ? null : OlaLatLng.fromJson(map);
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onMapReady':
        if (!_ready.isCompleted) _ready.complete();
      case 'onMapError':
        final error = call.arguments?.toString() ?? 'Unknown map error';
        _loadError = error;
        if (!_ready.isCompleted) _ready.complete();
        onMapError?.call(formatOlaMapError(error));
      case 'onMapClick':
        final point = _latLng(call.arguments);
        if (point != null) onMapClick?.call(point);
      case 'onMapLongClick':
        final point = _latLng(call.arguments);
        if (point != null) onMapLongClick?.call(point);
      case 'onMarkerClick':
        final markerId = _asMap(call.arguments)?['markerId']?.toString();
        if (markerId != null) onMarkerClick?.call(markerId);
      case 'onCameraIdle':
        final point = _latLng(call.arguments);
        if (point != null) onCameraIdle?.call(point);
    }
  }

  /// Completes when the native map is ready, or throws a formatted error.
  Future<void> waitUntilReady() async {
    if (_loadError != null) {
      throw formatOlaMapError(_loadError!);
    }
    if (!_ready.isCompleted) {
      try {
        await _invoke('waitUntilMapReady');
      } on PlatformException catch (e) {
        _loadError = e;
        throw formatOlaMapError(e);
      }
      if (!_ready.isCompleted) _ready.complete();
    }
    if (_loadError != null) {
      throw formatOlaMapError(_loadError!);
    }
  }

  /// Releases channels and callbacks for this map instance.
  void dispose() {
    _cameraSub?.cancel();
    _cameraSub = null;
    onCameraIdle = null;
    onMapClick = null;
    onMapLongClick = null;
    onMarkerClick = null;
    onMapError = null;
    olaMapListen(id, null);
    olaMapDisposeChannel(id);
    _controllers.remove(id);
  }

  /// Web-only init. Mobile maps are created from platform-view params.
  Future<void> initializeView(Map<String, dynamic> params) async {
    try {
      await _invoke('initialize', params);
    } on MissingPluginException {
      // Mobile SDKs create the map from PlatformView creationParams.
    }
  }

  /// Adds a marker and returns its id, or `null` if the call failed.
  Future<String?> addMarker({
    required OlaLatLng position,
    String? markerId,
    bool isClickable = true,
    double iconRotation = 0.0,
    bool isAnimationEnabled = true,
    String? snippet,
    String? subSnippet,
    bool isInfoWindowDismissOnClick = true,
    String? iconPath,
    String? iconAnchor,
    double? iconSize,
    List<double>? iconOffset,
  }) {
    return _runForId('addMarker', {
      'markerId': markerId ?? _nextOverlayId(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'isClickable': isClickable,
      'iconRotation': iconRotation,
      'isAnimationEnabled': isAnimationEnabled,
      'snippet': snippet,
      'subSnippet': subSnippet,
      'isInfoWindowDismissOnClick': isInfoWindowDismissOnClick,
      'iconPath': iconPath,
      'iconAnchor': iconAnchor,
      'iconSize': iconSize,
      'iconOffset': iconOffset,
    });
  }

  /// Removes the marker created with [addMarker].
  Future<void> removeMarker(String markerId) {
    return _run('removeMarker', {'markerId': markerId});
  }

  /// Updates position, icon, or snippet of an existing marker.
  Future<void> updateMarker({
    required String markerId,
    OlaLatLng? position,
    double? iconRotation,
    String? iconAnchor,
    String? iconPath,
    List<double>? iconOffset,
    double? iconSize,
    String? snippet,
    String? subSnippet,
  }) {
    return _run('updateMarker', {
      'markerId': markerId,
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
      if (iconRotation != null) 'iconRotation': iconRotation,
      if (iconAnchor != null) 'iconAnchor': iconAnchor,
      if (iconPath != null) 'iconPath': iconPath,
      if (iconOffset != null) 'iconOffset': iconOffset,
      if (iconSize != null) 'iconSize': iconSize,
      if (snippet != null) 'snippet': snippet,
      if (subSnippet != null) 'subSnippet': subSnippet,
    });
  }

  /// Shows the info window for [markerId].
  Future<void> showInfoWindow(String markerId) {
    return _run('showInfoWindow', {'markerId': markerId});
  }

  /// Hides the info window for [markerId].
  Future<void> hideInfoWindow(String markerId) {
    return _run('hideInfoWindow', {'markerId': markerId});
  }

  /// Replaces the info-window title for [markerId].
  Future<void> updateInfoWindow(String markerId, String text) {
    return _run('updateInfoWindow', {'markerId': markerId, 'text': text});
  }

  /// Draws a polyline and returns its id.
  Future<String?> addPolyline({
    required List<OlaLatLng> points,
    String? polylineId,
    String? color,
    String? lineType,
    double? width,
  }) {
    return _runForId('addPolyline', {
      'polylineId': polylineId ?? _nextOverlayId(),
      'points': points.map((p) => p.toJson()).toList(),
      'color': color,
      'lineType': lineType,
      'width': width,
    });
  }

  /// Removes a polyline created with [addPolyline].
  Future<void> removePolyline(String polylineId) {
    return _run('removePolyline', {'polylineId': polylineId});
  }

  /// Updates points or style of an existing polyline.
  Future<void> updatePolyline({
    required String polylineId,
    List<OlaLatLng>? points,
    String? color,
    double? width,
    String? lineType,
  }) {
    return _run('updatePolyline', {
      'polylineId': polylineId,
      if (points != null) 'points': points.map((p) => p.toJson()).toList(),
      if (color != null) 'color': color,
      if (width != null) 'width': width,
      if (lineType != null) 'lineType': lineType,
    });
  }

  /// Draws a circle (radius in meters) and returns its id.
  Future<String?> addCircle({
    required OlaLatLng center,
    required double radius,
    String? circleId,
    String? color,
    double? blur,
    double? opacity,
    String? borderColor,
    double? borderWidth,
    String? borderLineType,
  }) {
    return _runForId('addCircle', {
      'circleId': circleId ?? _nextOverlayId(),
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'color': color,
      'blur': blur,
      'opacity': opacity,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'borderLineType': borderLineType,
    });
  }

  /// Removes a circle created with [addCircle].
  Future<void> removeCircle(String circleId) {
    return _run('removeCircle', {'circleId': circleId});
  }

  /// Updates center, radius, or style of an existing circle.
  Future<void> updateCircle({
    required String circleId,
    OlaLatLng? center,
    double? radius,
    String? color,
    double? opacity,
    double? blur,
    String? borderColor,
    double? borderWidth,
    String? borderLineType,
  }) {
    return _run('updateCircle', {
      'circleId': circleId,
      if (center != null) 'latitude': center.latitude,
      if (center != null) 'longitude': center.longitude,
      if (radius != null) 'radius': radius,
      if (color != null) 'color': color,
      if (opacity != null) 'opacity': opacity,
      if (blur != null) 'blur': blur,
      if (borderColor != null) 'borderColor': borderColor,
      if (borderWidth != null) 'borderWidth': borderWidth,
      if (borderLineType != null) 'borderLineType': borderLineType,
    });
  }

  /// Draws a filled polygon and returns its id.
  Future<String?> addPolygon({
    required List<OlaLatLng> points,
    String? polygonId,
    String? color,
    String? borderColor,
    double? borderWidth,
    String? borderLineType,
  }) {
    return _runForId('addPolygon', {
      'polygonId': polygonId ?? _nextOverlayId(),
      'points': points.map((p) => p.toJson()).toList(),
      'color': color,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'borderLineType': borderLineType,
    });
  }

  /// Removes a polygon created with [addPolygon].
  Future<void> removePolygon(String polygonId) {
    return _run('removePolygon', {'polygonId': polygonId});
  }

  /// Updates points or style of an existing polygon.
  Future<void> updatePolygon({
    required String polygonId,
    List<OlaLatLng>? points,
    String? color,
    String? borderColor,
    double? borderWidth,
    String? borderLineType,
  }) {
    return _run('updatePolygon', {
      'polygonId': polygonId,
      if (points != null) 'points': points.map((p) => p.toJson()).toList(),
      if (color != null) 'color': color,
      if (borderColor != null) 'borderColor': borderColor,
      if (borderWidth != null) 'borderWidth': borderWidth,
      if (borderLineType != null) 'borderLineType': borderLineType,
    });
  }

  /// Draws a bezier curve between [startPoint] and [endPoint].
  Future<String?> addBezierCurve({
    required OlaLatLng startPoint,
    required OlaLatLng endPoint,
    String? curveId,
    String? color,
    String? lineType,
    double? width,
  }) {
    return _runForId('addBezierCurve', {
      'curveId': curveId ?? _nextOverlayId(),
      'startLatitude': startPoint.latitude,
      'startLongitude': startPoint.longitude,
      'endLatitude': endPoint.latitude,
      'endLongitude': endPoint.longitude,
      'color': color,
      'lineType': lineType,
      'width': width,
    });
  }

  /// Removes a curve created with [addBezierCurve].
  Future<void> removeBezierCurve(String curveId) {
    return _run('removeBezierCurve', {'curveId': curveId});
  }

  /// Updates endpoints or style of an existing bezier curve.
  Future<void> updateBezierCurve({
    required String curveId,
    OlaLatLng? startPoint,
    OlaLatLng? endPoint,
    String? color,
    String? lineType,
    double? width,
  }) {
    return _run('updateBezierCurve', {
      'curveId': curveId,
      if (startPoint != null) 'startLatitude': startPoint.latitude,
      if (startPoint != null) 'startLongitude': startPoint.longitude,
      if (endPoint != null) 'endLatitude': endPoint.latitude,
      if (endPoint != null) 'endLongitude': endPoint.longitude,
      if (color != null) 'color': color,
      if (lineType != null) 'lineType': lineType,
      if (width != null) 'width': width,
    });
  }

  /// Animates the camera to [location] at [zoomLevel].
  Future<void> zoomToLocation(OlaLatLng location, double zoomLevel) {
    return _run('zoomToLocation', {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'zoomLevel': zoomLevel,
    });
  }

  /// Zooms in by one step.
  Future<void> zoomIn() => _run('zoomIn');

  /// Zooms out by one step.
  Future<void> zoomOut() => _run('zoomOut');

  /// Moves the camera to [target] over [durationMs] milliseconds.
  Future<void> moveCamera(
    OlaLatLng target, {
    double zoom = 15,
    int durationMs = 500,
  }) {
    return _run('moveCamera', {
      'latitude': target.latitude,
      'longitude': target.longitude,
      'zoomLevel': zoom,
      'durationMs': durationMs,
    });
  }

  /// Device location if available.
  Future<OlaLatLng?> getCurrentLocation() async {
    try {
      return _latLng(await _invoke('getCurrentLocation'));
    } catch (e) {
      debugPrint('Error getCurrentLocation: $e');
      return null;
    }
  }

  /// Camera target when the map is idle (center of the viewport).
  Future<OlaLatLng?> getCameraPosition() async {
    final camera = await getCamera();
    return camera?.target;
  }

  /// Current camera pose (target, zoom, bearing, tilt).
  Future<OlaCameraPosition?> getCamera() async {
    try {
      final result = await _invoke('getCameraPosition');
      final map = _asMap(result);
      return map == null ? null : OlaCameraPosition.fromJson(map);
    } catch (e) {
      debugPrint('Error getCameraPosition: $e');
      return null;
    }
  }

  /// Shows the location puck.
  Future<void> showCurrentLocation() => _run('showCurrentLocation');

  /// Hides the location puck.
  Future<void> hideCurrentLocation() => _run('hideCurrentLocation');

  /// Adds clustered markers from a GeoJSON FeatureCollection string.
  Future<String?> addClusteredMarkers({
    required String geoJson,
    int? clusterRadius,
    String? defaultMarkerColor,
    String? defaultClusterColor,
    double? textSize,
    String? textColor,
    String? stop1Color,
    String? stop2Color,
    String? iconPath,
  }) {
    return _runForId('addClusteredMarkers', {
      'geoJson': geoJson,
      'clusterRadius': clusterRadius,
      'defaultMarkerColor': defaultMarkerColor,
      'defaultClusterColor': defaultClusterColor,
      'textSize': textSize,
      'textColor': textColor,
      'stop1Color': stop1Color,
      'stop2Color': stop2Color,
      'iconPath': iconPath,
    });
  }

  /// Builds GeoJSON from [points] and adds a cluster layer.
  Future<String?> addClusteredMarkersFromPoints({
    required List<OlaLatLng> points,
    int? clusterRadius,
    String? defaultMarkerColor,
    String? defaultClusterColor,
    double? textSize,
    String? textColor,
    String? stop1Color,
    String? stop2Color,
    String? iconPath,
  }) {
    final geoJson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final point in points)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [point.longitude, point.latitude],
            },
            'properties': <String, dynamic>{},
          },
      ],
    });
    return addClusteredMarkers(
      geoJson: geoJson,
      clusterRadius: clusterRadius,
      defaultMarkerColor: defaultMarkerColor,
      defaultClusterColor: defaultClusterColor,
      textSize: textSize,
      textColor: textColor,
      stop1Color: stop1Color,
      stop2Color: stop2Color,
      iconPath: iconPath,
    );
  }

  /// Replaces the GeoJSON behind an existing cluster layer.
  Future<void> updateClusteredMarkers({
    required String clusterId,
    required String geoJson,
    int? clusterRadius,
    String? defaultMarkerColor,
    String? defaultClusterColor,
    double? textSize,
    String? textColor,
    String? stop1Color,
    String? stop2Color,
    String? iconPath,
  }) {
    return _run('updateClusteredMarkers', {
      'clusterId': clusterId,
      'geoJson': geoJson,
      'clusterRadius': clusterRadius,
      'defaultMarkerColor': defaultMarkerColor,
      'defaultClusterColor': defaultClusterColor,
      'textSize': textSize,
      'textColor': textColor,
      'stop1Color': stop1Color,
      'stop2Color': stop2Color,
      'iconPath': iconPath,
    });
  }

  /// Removes a cluster layer created with [addClusteredMarkers].
  Future<void> removeClusteredMarkers(String clusterId) {
    return _run('removeClusteredMarkers', {'clusterId': clusterId});
  }
}
