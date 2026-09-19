import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ola_maps/src/map/ola_map_auth.dart';
import 'package:ola_maps/src/map/ola_map_controller.dart';
import 'package:ola_maps/src/map/ola_map_models.dart';
import 'package:ola_maps/src/utilities/ola_maps_language.dart';

/// Native (Android / iOS) or web map surface backed by the Ola Maps SDKs.
class OlaMapView extends StatefulWidget {
  /// Dashboard API key. May be empty when [tileUrl] uses a backend proxy.
  final String apiKey;

  /// Vector style URL. Defaults to [kOlaMapsDefaultTileUrl].
  final String tileUrl;

  /// ISO 639-1 code or [OlaMapsLanguage]. Dynamic Maps load
  /// `default-light-standard-{code}` unless [tileUrl] is a custom style.
  final Object? language;

  /// Web SDK `mode: "3d"` plus [threeDTileset].
  final bool mode3d;

  /// 3D tileset URL used when [mode3d] is true.
  final String? threeDTileset;

  /// Ola Maps project / workspace id (required by iOS `OlaMapService`).
  final String projectId;

  /// Optional end-user id forwarded to the iOS SDK.
  final String? userId;

  /// Called with the platform-view id after the native view is created.
  final void Function(int id)? onMapCreated;

  /// Called when overlays can be added.
  final void Function(OlaMapController controller)? onControllerReady;

  /// Called when style load or native init fails.
  final void Function(String error)? onMapError;

  /// Optional starting camera target.
  final OlaLatLng? initialCameraPosition;

  /// Zoom used with [initialCameraPosition].
  final double initialZoom;

  /// Shows Android zoom +/- buttons.
  final bool showZoomControls;

  /// Shows the compass control when the camera is rotated.
  final bool showCompass;

  /// Shows the "my location" FAB when location is enabled.
  final bool showMyLocationButton;

  /// Draws the device location puck.
  final bool myLocationEnabled;

  /// Allows pinch / double-tap zoom.
  final bool zoomGesturesEnabled;

  /// Allows panning the map.
  final bool scrollGesturesEnabled;

  /// Allows two-finger tilt.
  final bool tiltGesturesEnabled;

  /// Allows rotate gestures.
  final bool rotateGesturesEnabled;

  /// Allows double-tap zoom.
  final bool doubleTapGesturesEnabled;

  /// Creates an Ola Maps platform view.
  const OlaMapView({
    super.key,
    required this.apiKey,
    this.tileUrl = kOlaMapsDefaultTileUrl,
    this.language,
    this.mode3d = false,
    this.threeDTileset,
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
  void initState() {
    super.initState();
    if (canCreateOlaMapView(
      apiKey: widget.apiKey,
      tileUrl: widget.tileUrl,
    )) {
      return;
    }
    _loadError = formatOlaMapError('HTTP status code 403');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapError?.call(_loadError!);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _creationParams => <String, dynamic>{
        'apiKey': widget.apiKey,
        'tileUrl': OlaMapsLanguage.resolveTileUrl(
          widget.tileUrl,
          language: widget.language,
        ),
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
        'mode3d': widget.mode3d,
        'threeDTileset': widget.threeDTileset ?? kOlaMapsDefaultThreeDTileset,
        if (widget.initialCameraPosition != null) ...{
          'initialLatitude': widget.initialCameraPosition!.latitude,
          'initialLongitude': widget.initialCameraPosition!.longitude,
          'initialZoom': widget.initialZoom,
        },
      };

  Future<void> _onPlatformViewCreated(int id) async {
    final controller = OlaMapController.forPlatformView(id);
    _controller = controller;
    try {
      await controller.initializeView(_creationParams);
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
    if (kIsWeb) {
      return HtmlElementView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
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
        viewController
            .addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
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
