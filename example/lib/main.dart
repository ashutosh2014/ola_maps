import 'package:flutter/material.dart';
import 'package:ola_maps/ola_maps.dart';
import 'package:permission_handler/permission_handler.dart';

const String kOlaMapsApiKey = String.fromEnvironment(
  'OLA_MAPS_API_KEY',
  defaultValue: 'YOUR_API_KEY',
);

const OlaLatLng kOlaCampus = OlaLatLng(18.52145653681468, 73.93178277572254);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  OlaMapController? _controller;
  late final OlaRoutingService _routingService;

  String? _lastMarkerId;
  String? _lastPolylineId;
  String? _lastCircleId;
  String? _lastPolygonId;
  String? _lastBezierCurveId;
  String? _lastClusterId;
  String? _status;

  static const double _storeLat = 18.76029027465273;
  static const double _storeLng = 73.3814242364375;
  static const double _orderLat = 18.73354223011708;
  static const double _orderLng = 73.44587966939002;

  @override
  void initState() {
    super.initState();
    _routingService = OlaRoutingService(apiKey: kOlaMapsApiKey);
    Permission.location.request();
  }

  void _setStatus(String message) {
    setState(() => _status = message);
    debugPrint(message);
  }

  Future<void> _addMarker() async {
    final markerId = await _controller?.addMarker(
      position: kOlaCampus,
      isClickable: true,
      snippet: 'Ola Campus',
      subSnippet: 'Pune',
    );
    setState(() => _lastMarkerId = markerId);
    _setStatus('Marker added: $markerId');
  }

  Future<void> _removeMarker() async {
    final id = _lastMarkerId;
    if (id == null) return;
    await _controller?.removeMarker(id);
    setState(() => _lastMarkerId = null);
    _setStatus('Marker removed');
  }

  Future<void> _addPolyline() async {
    final polylineId = await _controller?.addPolyline(
      points: const [
        OlaLatLng(18.52145653681468, 73.93178277572254),
        OlaLatLng(18.52345653681468, 73.93378277572254),
        OlaLatLng(18.52545653681468, 73.93578277572254),
      ],
      color: '#FF0000',
      width: 5,
      lineType: OlaLineType.solid,
    );
    setState(() => _lastPolylineId = polylineId);
    _setStatus('Polyline added: $polylineId');
  }

  Future<void> _removePolyline() async {
    final id = _lastPolylineId;
    if (id == null) return;
    await _controller?.removePolyline(id);
    setState(() => _lastPolylineId = null);
    _setStatus('Polyline removed');
  }

  Future<void> _addCircle() async {
    final circleId = await _controller?.addCircle(
      center: kOlaCampus,
      radius: 500,
      color: '#0000FF',
      opacity: 0.3,
      borderColor: '#0000FF',
      borderWidth: 2,
    );
    setState(() => _lastCircleId = circleId);
    _setStatus('Circle added: $circleId');
  }

  Future<void> _removeCircle() async {
    final id = _lastCircleId;
    if (id == null) return;
    await _controller?.removeCircle(id);
    setState(() => _lastCircleId = null);
    _setStatus('Circle removed');
  }

  Future<void> _addPolygon() async {
    final polygonId = await _controller?.addPolygon(
      points: const [
        OlaLatLng(18.52145653681468, 73.93178277572254),
        OlaLatLng(18.52345653681468, 73.93378277572254),
        OlaLatLng(18.52545653681468, 73.93578277572254),
        OlaLatLng(18.52545653681468, 73.93178277572254),
      ],
      color: '#00FF00',
      borderColor: '#006600',
      borderWidth: 2,
    );
    setState(() => _lastPolygonId = polygonId);
    _setStatus('Polygon added: $polygonId');
  }

  Future<void> _removePolygon() async {
    final id = _lastPolygonId;
    if (id == null) return;
    await _controller?.removePolygon(id);
    setState(() => _lastPolygonId = null);
    _setStatus('Polygon removed');
  }

  Future<void> _addBezierCurve() async {
    final curveId = await _controller?.addBezierCurve(
      startPoint: kOlaCampus,
      endPoint: const OlaLatLng(18.52545653681468, 73.93578277572254),
      color: '#FF00FF',
      width: 4,
      lineType: OlaLineType.solid,
    );
    setState(() => _lastBezierCurveId = curveId);
    _setStatus('Bezier curve added: $curveId');
  }

  Future<void> _removeBezierCurve() async {
    final id = _lastBezierCurveId;
    if (id == null) return;
    await _controller?.removeBezierCurve(id);
    setState(() => _lastBezierCurveId = null);
    _setStatus('Bezier curve removed');
  }

  Future<void> _addClusters() async {
    final clusterId = await _controller?.addClusteredMarkersFromPoints(
      points: const [
        OlaLatLng(18.5214, 73.9317),
        OlaLatLng(18.5220, 73.9325),
        OlaLatLng(18.5235, 73.9338),
        OlaLatLng(18.5248, 73.9349),
        OlaLatLng(18.5260, 73.9360),
        OlaLatLng(18.5180, 73.9280),
        OlaLatLng(18.5195, 73.9295),
      ],
      clusterRadius: 50,
      defaultMarkerColor: '#FF0000',
      defaultClusterColor: '#00AA00',
      textColor: '#FFFFFF',
      textSize: 12,
    );
    setState(() => _lastClusterId = clusterId);
    _setStatus('Clusters added: $clusterId');
  }

  Future<void> _removeClusters() async {
    final id = _lastClusterId;
    if (id == null) return;
    await _controller?.removeClusteredMarkers(id);
    setState(() => _lastClusterId = null);
    _setStatus('Clusters removed');
  }

  Future<void> _drawRoute() async {
    if (_controller == null) return;
    _setStatus('Fetching route...');
    try {
      final routePoints = await _routingService.getDirections(
        originLat: _storeLat,
        originLng: _storeLng,
        destLat: _orderLat,
        destLng: _orderLng,
      );
      final olaPoints = routePoints
          .map((point) => OlaLatLng(point['lat']!, point['lng']!))
          .toList();

      if (_lastPolylineId != null) {
        await _controller!.removePolyline(_lastPolylineId!);
      }

      final polylineId = await _controller!.addPolyline(
        points: olaPoints,
        color: '#0000FF',
        width: 5,
      );
      await _controller!.addMarker(
        position: const OlaLatLng(_storeLat, _storeLng),
        snippet: 'Store',
      );
      await _controller!.addMarker(
        position: const OlaLatLng(_orderLat, _orderLng),
        snippet: 'Order',
      );
      await _controller!.zoomToLocation(
        OlaLatLng((_storeLat + _orderLat) / 2, (_storeLng + _orderLng) / 2),
        12,
      );
      setState(() => _lastPolylineId = polylineId);
      _setStatus('Route drawn (${olaPoints.length} points)');
    } catch (e) {
      _setStatus('Route error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ola Maps Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ola Maps Example'),
        ),
        body: Stack(
          children: [
            OlaMapView(
              apiKey: kOlaMapsApiKey,
              initialCameraPosition: kOlaCampus,
              initialZoom: 14,
              onMapError: _setStatus,
              onControllerReady: (controller) {
                setState(() => _controller = controller);
                controller.onMapClick = (pos) {
                  _setStatus(
                    'Tap ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                  );
                };
                controller.onMarkerClick = (id) {
                  _setStatus('Marker tapped: $id');
                  controller.showInfoWindow(id);
                };
                _setStatus('Map ready');
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _status ??
                        (kOlaMapsApiKey == 'YOUR_API_KEY'
                            ? 'Pass --dart-define=OLA_MAPS_API_KEY=...'
                            : 'Loading map...'),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 96,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: _controller == null
                        ? null
                        : () => _controller!.zoomIn(),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: _controller == null
                        ? null
                        : () => _controller!.zoomOut(),
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'my_location',
                    onPressed: _controller == null
                        ? null
                        : () async {
                            await _controller!.showCurrentLocation();
                            final location =
                                await _controller!.getCurrentLocation();
                            if (location != null) {
                              await _controller!.zoomToLocation(location, 16);
                              _setStatus('Current location');
                            } else {
                              _setStatus('Location unavailable');
                            }
                          },
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          elevation: 8,
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _ActionChip(
                    label: 'Marker',
                    icon: Icons.add_location,
                    onPressed: _controller == null ? null : _addMarker,
                  ),
                  _ActionChip(
                    label: 'Remove',
                    icon: Icons.remove_circle,
                    onPressed: _lastMarkerId == null ? null : _removeMarker,
                  ),
                  _ActionChip(
                    label: 'Line',
                    icon: Icons.timeline,
                    onPressed: _controller == null ? null : _addPolyline,
                  ),
                  _ActionChip(
                    label: 'Clear line',
                    icon: Icons.clear,
                    onPressed: _lastPolylineId == null ? null : _removePolyline,
                  ),
                  _ActionChip(
                    label: 'Circle',
                    icon: Icons.circle_outlined,
                    onPressed: _controller == null ? null : _addCircle,
                  ),
                  _ActionChip(
                    label: 'Clear circle',
                    icon: Icons.cancel_outlined,
                    onPressed: _lastCircleId == null ? null : _removeCircle,
                  ),
                  _ActionChip(
                    label: 'Polygon',
                    icon: Icons.hexagon_outlined,
                    onPressed: _controller == null ? null : _addPolygon,
                  ),
                  _ActionChip(
                    label: 'Clear polygon',
                    icon: Icons.delete_outline,
                    onPressed: _lastPolygonId == null ? null : _removePolygon,
                  ),
                  _ActionChip(
                    label: 'Bezier',
                    icon: Icons.show_chart,
                    onPressed: _controller == null ? null : _addBezierCurve,
                  ),
                  _ActionChip(
                    label: 'Clear bezier',
                    icon: Icons.close,
                    onPressed:
                        _lastBezierCurveId == null ? null : _removeBezierCurve,
                  ),
                  _ActionChip(
                    label: 'Cluster',
                    icon: Icons.bubble_chart,
                    onPressed: _controller == null ? null : _addClusters,
                  ),
                  _ActionChip(
                    label: 'Clear cluster',
                    icon: Icons.blur_off,
                    onPressed: _lastClusterId == null ? null : _removeClusters,
                  ),
                  _ActionChip(
                    label: 'Route',
                    icon: Icons.route,
                    onPressed: _controller == null ? null : _drawRoute,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
