import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

export 'ola_routing_service.dart';

/// Geographic coordinate used by the Ola Maps SDK.
class OlaLatLng {
  final double latitude;
  final double longitude;

  const OlaLatLng(this.latitude, this.longitude);

  factory OlaLatLng.fromJson(Map<dynamic, dynamic> json) {
    return OlaLatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  bool operator ==(Object other) {
    return other is OlaLatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'OlaLatLng($latitude, $longitude)';
}

/// Camera target plus zoom / bearing / tilt.
class OlaCameraPosition {
  final OlaLatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  const OlaCameraPosition({
    required this.target,
    this.zoom = 15,
    this.bearing = 0,
    this.tilt = 0,
  });

  factory OlaCameraPosition.fromJson(Map<dynamic, dynamic> json) {
    return OlaCameraPosition(
      target: OlaLatLng.fromJson(json),
      zoom: (json['zoom'] as num?)?.toDouble() ?? 0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
      tilt: (json['tilt'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() =>
      'OlaCameraPosition(target: $target, zoom: $zoom, bearing: $bearing, tilt: $tilt)';
}

/// Line styles accepted by polylines and bezier curves.
class OlaLineType {
  static const solid = 'LINE_SOLID';
  static const dotted = 'LINE_DOTTED';
}

bool isOlaMapsApiKeyConfigured(String apiKey) {
  final key = apiKey.trim();
  if (key.isEmpty) return false;
  return key != 'YOUR_API_KEY' && key != 'YOUR_OLA_MAPS_API_KEY' && key != '<API KEY>';
}

String formatOlaMapError(Object error) {
  final raw = error is PlatformException
      ? (error.message ?? error.code)
      : error.toString();
  if (raw.contains('403')) {
    return 'Ola Maps rejected the style request (HTTP 403). '
        'Use a real API key from https://maps.olakrutrim.com/ and run:\n'
        'flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY';
  }
  if (raw.contains('401')) {
    return 'Ola Maps authentication failed (HTTP 401). Check the API key.';
  }
  return raw;
}

class OlaMapController {
  final int id;
  final MethodChannel _channel;
  final EventChannel _cameraChannel;
  StreamSubscription? _cameraSub;
  final Completer<void> _ready = Completer<void>();
  Object? _loadError;

  void Function(OlaLatLng position)? onCameraIdle;
  void Function(OlaLatLng position)? onMapClick;
  void Function(OlaLatLng position)? onMapLongClick;
  void Function(String markerId)? onMarkerClick;
  void Function(String error)? onMapError;

  OlaMapController._(this.id)
      : _channel = MethodChannel('ola_map_view_flutter_$id'),
        _cameraChannel = EventChannel('ola_map_view_flutter_camera_$id') {
    _channel.setMethodCallHandler(_onNativeCall);
    _cameraSub = _cameraChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        onCameraIdle?.call(OlaLatLng.fromJson(event));
      }
    });
  }

  static final Map<int, OlaMapController> _controllers = {};

  static OlaMapController _getController(int id) {
    return _controllers.putIfAbsent(id, () => OlaMapController._(id));
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onMapReady':
        if (!_ready.isCompleted) _ready.complete();
        break;
      case 'onMapError':
        final error = call.arguments?.toString() ?? 'Unknown map error';
        _loadError = error;
        if (!_ready.isCompleted) _ready.complete();
        onMapError?.call(formatOlaMapError(error));
        break;
      case 'onMapClick':
        final args = call.arguments;
        if (args is Map) onMapClick?.call(OlaLatLng.fromJson(args));
        break;
      case 'onMapLongClick':
        final args = call.arguments;
        if (args is Map) onMapLongClick?.call(OlaLatLng.fromJson(args));
        break;
      case 'onMarkerClick':
        final args = call.arguments;
        if (args is Map) {
          final markerId = args['markerId']?.toString();
          if (markerId != null) onMarkerClick?.call(markerId);
        }
        break;
    }
  }

  Future<void> waitUntilReady() async {
    if (_loadError != null) {
      throw formatOlaMapError(_loadError!);
    }
    if (!_ready.isCompleted) {
      try {
        await _channel.invokeMethod('waitUntilMapReady');
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

  void dispose() {
    _cameraSub?.cancel();
    _cameraSub = null;
    onCameraIdle = null;
    onMapClick = null;
    onMapLongClick = null;
    onMarkerClick = null;
    onMapError = null;
    _channel.setMethodCallHandler(null);
    _controllers.remove(id);
  }

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
  }) async {
    try {
      final result = await _channel.invokeMethod('addMarker', {
        'markerId': markerId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      return result as String?;
    } catch (e) {
      debugPrint('Error adding marker: $e');
      return null;
    }
  }

  Future<void> removeMarker(String markerId) async {
    try {
      await _channel.invokeMethod('removeMarker', {'markerId': markerId});
    } catch (e) {
      debugPrint('Error removing marker: $e');
    }
  }

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
  }) async {
    try {
      final args = <String, dynamic>{'markerId': markerId};
      if (position != null) {
        args['latitude'] = position.latitude;
        args['longitude'] = position.longitude;
      }
      if (iconRotation != null) args['iconRotation'] = iconRotation;
      if (iconAnchor != null) args['iconAnchor'] = iconAnchor;
      if (iconPath != null) args['iconPath'] = iconPath;
      if (iconOffset != null) args['iconOffset'] = iconOffset;
      if (iconSize != null) args['iconSize'] = iconSize;
      if (snippet != null) args['snippet'] = snippet;
      if (subSnippet != null) args['subSnippet'] = subSnippet;
      await _channel.invokeMethod('updateMarker', args);
    } catch (e) {
      debugPrint('Error updating marker: $e');
    }
  }

  Future<void> showInfoWindow(String markerId) async {
    try {
      await _channel.invokeMethod('showInfoWindow', {'markerId': markerId});
    } catch (e) {
      debugPrint('Error showing info window: $e');
    }
  }

  Future<void> hideInfoWindow(String markerId) async {
    try {
      await _channel.invokeMethod('hideInfoWindow', {'markerId': markerId});
    } catch (e) {
      debugPrint('Error hiding info window: $e');
    }
  }

  Future<void> updateInfoWindow(String markerId, String text) async {
    try {
      await _channel.invokeMethod('updateInfoWindow', {
        'markerId': markerId,
        'text': text,
      });
    } catch (e) {
      debugPrint('Error updating info window: $e');
    }
  }

  Future<String?> addPolyline({
    required List<OlaLatLng> points,
    String? polylineId,
    String? color,
    String? lineType,
    double? width,
  }) async {
    try {
      final result = await _channel.invokeMethod('addPolyline', {
        'polylineId':
            polylineId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'points': points.map((p) => p.toJson()).toList(),
        'color': color,
        'lineType': lineType,
        'width': width,
      });
      return result as String?;
    } catch (e) {
      debugPrint('Error adding polyline: $e');
      return null;
    }
  }

  Future<void> removePolyline(String polylineId) async {
    try {
      await _channel.invokeMethod('removePolyline', {'polylineId': polylineId});
    } catch (e) {
      debugPrint('Error removing polyline: $e');
    }
  }

  Future<void> updatePolyline({
    required String polylineId,
    List<OlaLatLng>? points,
    String? color,
    double? width,
    String? lineType,
  }) async {
    try {
      final args = <String, dynamic>{'polylineId': polylineId};
      if (points != null) {
        args['points'] = points.map((p) => p.toJson()).toList();
      }
      if (color != null) args['color'] = color;
      if (width != null) args['width'] = width;
      if (lineType != null) args['lineType'] = lineType;
      await _channel.invokeMethod('updatePolyline', args);
    } catch (e) {
      debugPrint('Error updating polyline: $e');
    }
  }

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
  }) async {
    try {
      final result = await _channel.invokeMethod('addCircle', {
        'circleId':
            circleId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      return result as String?;
    } catch (e) {
      debugPrint('Error adding circle: $e');
      return null;
    }
  }

  Future<void> removeCircle(String circleId) async {
    try {
      await _channel.invokeMethod('removeCircle', {'circleId': circleId});
    } catch (e) {
      debugPrint('Error removing circle: $e');
    }
  }

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
  }) async {
    try {
      final args = <String, dynamic>{'circleId': circleId};
      if (center != null) {
        args['latitude'] = center.latitude;
        args['longitude'] = center.longitude;
      }
      if (radius != null) args['radius'] = radius;
      if (color != null) args['color'] = color;
      if (opacity != null) args['opacity'] = opacity;
      if (blur != null) args['blur'] = blur;
      if (borderColor != null) args['borderColor'] = borderColor;
      if (borderWidth != null) args['borderWidth'] = borderWidth;
      if (borderLineType != null) args['borderLineType'] = borderLineType;
      await _channel.invokeMethod('updateCircle', args);
    } catch (e) {
      debugPrint('Error updating circle: $e');
    }
  }

  Future<String?> addPolygon({
    required List<OlaLatLng> points,
    String? polygonId,
    String? color,
    String? borderColor,
    double? borderWidth,
    String? borderLineType,
  }) async {
    try {
      final result = await _channel.invokeMethod('addPolygon', {
        'polygonId':
            polygonId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'points': points.map((p) => p.toJson()).toList(),
        'color': color,
        'borderColor': borderColor,
        'borderWidth': borderWidth,
        'borderLineType': borderLineType,
      });
      return result as String?;
    } catch (e) {
      debugPrint('Error adding polygon: $e');
      return null;
    }
  }

  Future<void> removePolygon(String polygonId) async {
    try {
      await _channel.invokeMethod('removePolygon', {'polygonId': polygonId});
    } catch (e) {
      debugPrint('Error removing polygon: $e');
    }
  }

  Future<void> updatePolygon({
    required String polygonId,
    List<OlaLatLng>? points,
    String? color,
    String? borderColor,
    double? borderWidth,
    String? borderLineType,
  }) async {
    try {
      final args = <String, dynamic>{'polygonId': polygonId};
      if (points != null) {
        args['points'] = points.map((p) => p.toJson()).toList();
      }
      if (color != null) args['color'] = color;
      if (borderColor != null) args['borderColor'] = borderColor;
      if (borderWidth != null) args['borderWidth'] = borderWidth;
      if (borderLineType != null) args['borderLineType'] = borderLineType;
      await _channel.invokeMethod('updatePolygon', args);
    } catch (e) {
      debugPrint('Error updating polygon: $e');
    }
  }

  Future<String?> addBezierCurve({
    required OlaLatLng startPoint,
    required OlaLatLng endPoint,
    String? curveId,
    String? color,
    String? lineType,
    double? width,
  }) async {
    try {
      final result = await _channel.invokeMethod('addBezierCurve', {
        'curveId': curveId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'startLatitude': startPoint.latitude,
        'startLongitude': startPoint.longitude,
        'endLatitude': endPoint.latitude,
        'endLongitude': endPoint.longitude,
        'color': color,
        'lineType': lineType,
        'width': width,
      });
      return result as String?;
    } catch (e) {
      debugPrint('Error adding bezier curve: $e');
      return null;
    }
  }

  Future<void> removeBezierCurve(String curveId) async {
    try {
      await _channel.invokeMethod('removeBezierCurve', {'curveId': curveId});
    } catch (e) {
      debugPrint('Error removing bezier curve: $e');
    }
  }

  Future<void> updateBezierCurve({
    required String curveId,
    OlaLatLng? startPoint,
    OlaLatLng? endPoint,
    String? color,
    String? lineType,
    double? width,
  }) async {
    try {
      final args = <String, dynamic>{'curveId': curveId};
      if (startPoint != null) {
        args['startLatitude'] = startPoint.latitude;
        args['startLongitude'] = startPoint.longitude;
      }
      if (endPoint != null) {
        args['endLatitude'] = endPoint.latitude;
        args['endLongitude'] = endPoint.longitude;
      }
      if (color != null) args['color'] = color;
      if (lineType != null) args['lineType'] = lineType;
      if (width != null) args['width'] = width;
      await _channel.invokeMethod('updateBezierCurve', args);
    } catch (e) {
      debugPrint('Error updating bezier curve: $e');
    }
  }

  Future<void> zoomToLocation(OlaLatLng location, double zoomLevel) async {
    try {
      await _channel.invokeMethod('zoomToLocation', {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'zoomLevel': zoomLevel,
      });
    } catch (e) {
      debugPrint('Error zooming to location: $e');
    }
  }

  Future<void> zoomIn() async {
    try {
      await _channel.invokeMethod('zoomIn');
    } catch (e) {
      debugPrint('Error zooming in: $e');
    }
  }

  Future<void> zoomOut() async {
    try {
      await _channel.invokeMethod('zoomOut');
    } catch (e) {
      debugPrint('Error zooming out: $e');
    }
  }

  Future<void> moveCamera(
    OlaLatLng target, {
    double zoom = 15,
    int durationMs = 500,
  }) async {
    try {
      await _channel.invokeMethod('moveCamera', {
        'latitude': target.latitude,
        'longitude': target.longitude,
        'zoomLevel': zoom,
        'durationMs': durationMs,
      });
    } catch (e) {
      debugPrint('Error moving camera: $e');
    }
  }

  Future<OlaLatLng?> getCurrentLocation() async {
    try {
      final result = await _channel.invokeMethod('getCurrentLocation');
      if (result is Map) return OlaLatLng.fromJson(result);
      return null;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Camera target when the map is idle (center of the viewport).
  Future<OlaLatLng?> getCameraPosition() async {
    final camera = await getCamera();
    return camera?.target;
  }

  Future<OlaCameraPosition?> getCamera() async {
    try {
      final result = await _channel.invokeMethod('getCameraPosition');
      if (result is Map) return OlaCameraPosition.fromJson(result);
      return null;
    } catch (e) {
      debugPrint('Error getting camera position: $e');
      return null;
    }
  }

  Future<void> showCurrentLocation() async {
    try {
      await _channel.invokeMethod('showCurrentLocation');
    } catch (e) {
      debugPrint('Error showing current location: $e');
    }
  }

  Future<void> hideCurrentLocation() async {
    try {
      await _channel.invokeMethod('hideCurrentLocation');
    } catch (e) {
      debugPrint('Error hiding current location: $e');
    }
  }

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
  }) async {
    try {
      final result = await _channel.invokeMethod('addClusteredMarkers', {
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
      return result as String?;
    } catch (e) {
      debugPrint('Error adding clustered markers: $e');
      return null;
    }
  }

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
  }) async {
    try {
      await _channel.invokeMethod('updateClusteredMarkers', {
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
    } catch (e) {
      debugPrint('Error updating clustered markers: $e');
    }
  }

  Future<void> removeClusteredMarkers(String clusterId) async {
    try {
      await _channel
          .invokeMethod('removeClusteredMarkers', {'clusterId': clusterId});
    } catch (e) {
      debugPrint('Error removing clustered markers: $e');
    }
  }
}

/// Default vector style used by the Ola Maps iOS SDK (`OlaMapService` tileURL).
const String kOlaMapsDefaultTileUrl =
    'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json';

class OlaMapView extends StatefulWidget {
  final String apiKey;
  final String tileUrl;
  final String projectId;
  final String? userId;
  final void Function(int id)? onMapCreated;
  final void Function(OlaMapController controller)? onControllerReady;
  final void Function(String error)? onMapError;
  final OlaLatLng? initialCameraPosition;
  final double initialZoom;
  final bool showZoomControls;
  final bool showCompass;
  final bool showMyLocationButton;
  final bool myLocationEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool doubleTapGesturesEnabled;

  const OlaMapView({
    super.key,
    required this.apiKey,
    this.tileUrl = kOlaMapsDefaultTileUrl,
    this.projectId = '',
    this.userId,
    this.onMapCreated,
    this.onControllerReady,
    this.onMapError,
    this.initialCameraPosition,
    this.initialZoom = 15,
    this.showZoomControls = true,
    this.showCompass = true,
    this.showMyLocationButton = true,
    this.myLocationEnabled = true,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.doubleTapGesturesEnabled = true,
  });

  @override
  State<OlaMapView> createState() => _OlaMapViewState();
}

class _OlaMapViewState extends State<OlaMapView> {
  OlaMapController? _controller;
  String? _loadError;

  static const String _viewType = 'ola_map_view_flutter';

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!isOlaMapsApiKeyConfigured(widget.apiKey)) {
      _loadError = formatOlaMapError('HTTP status code 403');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onMapError?.call(_loadError!);
      });
    }
  }

  Map<String, dynamic> get _creationParams => <String, dynamic>{
        'apiKey': widget.apiKey,
        'tileUrl': widget.tileUrl,
        'projectId': widget.projectId,
        'userId': widget.userId,
        'showZoomControls': widget.showZoomControls,
        'showCompass': widget.showCompass,
        'showMyLocationButton': widget.showMyLocationButton,
        'myLocationEnabled': widget.myLocationEnabled,
        'zoomGesturesEnabled': widget.zoomGesturesEnabled,
        'scrollGesturesEnabled': widget.scrollGesturesEnabled,
        'tiltGesturesEnabled': widget.tiltGesturesEnabled,
        'rotateGesturesEnabled': widget.rotateGesturesEnabled,
        'doubleTapGesturesEnabled': widget.doubleTapGesturesEnabled,
        if (widget.initialCameraPosition != null) ...{
          'initialLatitude': widget.initialCameraPosition!.latitude,
          'initialLongitude': widget.initialCameraPosition!.longitude,
          'initialZoom': widget.initialZoom,
        },
      };

  Future<void> _onPlatformViewCreated(int id) async {
    final controller = OlaMapController._getController(id);
    _controller = controller;
    try {
      await controller.waitUntilReady();
      if (!mounted) return;
      widget.onMapCreated?.call(id);
      widget.onControllerReady?.call(controller);
    } catch (e) {
      final message = formatOlaMapError(e);
      debugPrint('OlaMap failed to load: $message');
      if (mounted) {
        setState(() => _loadError = message);
      }
      widget.onMapError?.call(message);
    }
  }

  Widget _errorPane(String message) {
    return ColoredBox(
      color: const Color(0xFFF6F6F6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _errorPane(_loadError!);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidView();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosView();
    }
    return _errorPane(
      '${defaultTargetPlatform.name} is not yet supported by the Ola Maps plugin',
    );
  }

  Widget _androidView() {
    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
          },
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final viewController = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: _creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
        viewController.addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
        viewController.addOnPlatformViewCreatedListener(_onPlatformViewCreated);
        viewController.create();
        return viewController;
      },
    );
  }

  Widget _iosView() {
    return UiKitView(
      viewType: _viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: _creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }
}
