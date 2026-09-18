import 'package:flutter/material.dart';
import 'package:ola_maps/ola_maps.dart';
import 'package:permission_handler/permission_handler.dart';

import 'demo_data.dart';

const String kOlaMapsApiKey = String.fromEnvironment(
  'OLA_MAPS_API_KEY',
  defaultValue: 'YOUR_API_KEY',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ola Maps Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF222222),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          foregroundColor: Colors.white,
        ),
      ),
      home: const OlaMapsDemoPage(),
    );
  }
}

class OlaMapsDemoPage extends StatefulWidget {
  const OlaMapsDemoPage({super.key});

  @override
  State<OlaMapsDemoPage> createState() => _OlaMapsDemoPageState();
}

class _OlaMapsDemoPageState extends State<OlaMapsDemoPage> {
  OlaMapController? _controller;
  late final OlaRoutingService _routingService;

  String _status = isOlaMapsApiKeyConfigured(kOlaMapsApiKey)
      ? 'Loading Pune demo scene…'
      : 'Pass --dart-define=OLA_MAPS_API_KEY=YOUR_KEY';

  DemoPlace? _selectedPlace;
  OlaLatLng? _lastTap;

  final List<String> _placeMarkerIds = [];
  String? _zoneId;
  String? _coverageId;
  String? _tripLineId;
  String? _curveId;
  String? _clusterId;
  String? _routeId;
  String? _droppedPinId;

  bool get _mapReady => _controller != null;

  @override
  void initState() {
    super.initState();
    _routingService = OlaRoutingService(apiKey: kOlaMapsApiKey);
    Permission.location.request();
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
    debugPrint(message);
  }

  Future<void> _onMapReady(OlaMapController controller) async {
    setState(() => _controller = controller);
    controller.onMapClick = _onMapTap;
    controller.onMarkerClick = (id) {
      DemoPlace? place;
      for (final item in OlaMapsDemoData.places) {
        if (item.id == id) {
          place = item;
          break;
        }
      }
      setState(() => _selectedPlace = place);
      controller.showInfoWindow(id);
      _setStatus(place?.title ?? 'Marker $id');
    };
    await _showPlaces();
    _setStatus('Pune demo ready · tap the map or a layer below');
  }

  Future<void> _onMapTap(OlaLatLng position) async {
    setState(() => _lastTap = position);
    if (_droppedPinId != null) {
      await _controller?.removeMarker(_droppedPinId!);
    }
    final id = await _controller?.addMarker(
      markerId: 'dropped_pin',
      position: position,
      snippet: 'Dropped pin',
      subSnippet:
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      isClickable: true,
    );
    setState(() => _droppedPinId = id);
    _setStatus(
      'Pin ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
    );
  }

  Future<void> _showPlaces() async {
    if (_controller == null) return;
    await _clearPlaceMarkers();
    for (final place in OlaMapsDemoData.places) {
      final id = await _controller!.addMarker(
        markerId: place.id,
        position: place.position,
        snippet: place.title,
        subSnippet: place.subtitle,
        isClickable: true,
      );
      if (id != null) _placeMarkerIds.add(id);
    }
    await _controller!.zoomToLocation(
      OlaMapsDemoData.mapCenter,
      OlaMapsDemoData.mapZoom,
    );
    setState(() {});
    _setStatus('${OlaMapsDemoData.places.length} Pune places');
  }

  Future<void> _clearPlaceMarkers() async {
    for (final id in _placeMarkerIds) {
      await _controller?.removeMarker(id);
    }
    _placeMarkerIds.clear();
  }

  Future<void> _toggleDeliveryZone() async {
    if (_controller == null) return;
    if (_zoneId != null) {
      await _controller!.removePolygon(_zoneId!);
      setState(() => _zoneId = null);
      _setStatus('Delivery zone hidden');
      return;
    }
    final id = await _controller!.addPolygon(
      polygonId: 'magarpatta_zone',
      points: OlaMapsDemoData.deliveryZone,
      color: '#4CAF50',
      borderColor: '#1B8F3A',
      borderWidth: 3,
    );
    setState(() => _zoneId = id);
    await _controller!.zoomToLocation(OlaMapsDemoData.headquarters.position, 14.5);
    _setStatus('Magarpatta delivery zone');
  }

  Future<void> _toggleCoverage() async {
    if (_controller == null) return;
    if (_coverageId != null) {
      await _controller!.removeCircle(_coverageId!);
      setState(() => _coverageId = null);
      _setStatus('Coverage hidden');
      return;
    }
    final id = await _controller!.addCircle(
      circleId: 'hq_coverage',
      center: OlaMapsDemoData.coverageCenter,
      radius: OlaMapsDemoData.coverageRadiusMeters,
      color: '#2196F3',
      opacity: 0.25,
      borderColor: '#1565C0',
      borderWidth: 2,
    );
    setState(() => _coverageId = id);
    await _controller!.zoomToLocation(OlaMapsDemoData.coverageCenter, 13.2);
    _setStatus('1.8 km HQ coverage');
  }

  Future<void> _toggleTripLine() async {
    if (_controller == null) return;
    if (_tripLineId != null) {
      await _controller!.removePolyline(_tripLineId!);
      setState(() => _tripLineId = null);
      _setStatus('Trip path hidden');
      return;
    }
    final id = await _controller!.addPolyline(
      polylineId: 'hq_to_mall',
      points: OlaMapsDemoData.sampleTrip,
      color: '#111111',
      width: 6,
      lineType: OlaLineType.solid,
    );
    setState(() => _tripLineId = id);
    await _controller!.zoomToLocation(const OlaLatLng(18.5418, 73.9240), 13.2);
    _setStatus('HQ → Phoenix Mall path');
  }

  Future<void> _toggleBezier() async {
    if (_controller == null) return;
    if (_curveId != null) {
      await _controller!.removeBezierCurve(_curveId!);
      setState(() => _curveId = null);
      _setStatus('Flight curve hidden');
      return;
    }
    final id = await _controller!.addBezierCurve(
      curveId: 'pickup_to_drop',
      startPoint: OlaMapsDemoData.pickup.position,
      endPoint: OlaMapsDemoData.drop.position,
      color: '#E53935',
      width: 4,
      lineType: OlaLineType.solid,
    );
    setState(() => _curveId = id);
    await _controller!.zoomToLocation(const OlaLatLng(18.5490, 73.9050), 13);
    _setStatus('Mall → Koregaon Park curve');
  }

  Future<void> _toggleClusters() async {
    if (_controller == null) return;
    if (_clusterId != null) {
      await _controller!.removeClusteredMarkers(_clusterId!);
      setState(() => _clusterId = null);
      _setStatus('Dark stores hidden');
      return;
    }
    final id = await _controller!.addClusteredMarkersFromPoints(
      points: OlaMapsDemoData.nearbyStores,
      clusterRadius: 60,
      defaultMarkerColor: '#111111',
      defaultClusterColor: '#FBC02D',
      textColor: '#111111',
      textSize: 13,
    );
    setState(() => _clusterId = id);
    await _controller!.zoomToLocation(OlaMapsDemoData.headquarters.position, 13.8);
    _setStatus('${OlaMapsDemoData.nearbyStores.length} nearby dark stores');
  }

  Future<void> _drawLiveRoute() async {
    if (_controller == null) return;
    _setStatus('Fetching driving directions…');
    try {
      final origin = OlaMapsDemoData.pickup.position;
      final dest = OlaMapsDemoData.drop.position;
      final routePoints = await _routingService.getDirections(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: dest.latitude,
        destLng: dest.longitude,
      );
      final olaPoints = routePoints
          .map((point) => OlaLatLng(point['lat']!, point['lng']!))
          .toList();
      if (_routeId != null) {
        await _controller!.removePolyline(_routeId!);
      }
      final id = await _controller!.addPolyline(
        polylineId: 'live_route',
        points: olaPoints,
        color: '#1565C0',
        width: 7,
        lineType: OlaLineType.solid,
      );
      await _controller!.zoomToLocation(
        OlaLatLng(
          (origin.latitude + dest.latitude) / 2,
          (origin.longitude + dest.longitude) / 2,
        ),
        12.5,
      );
      setState(() => _routeId = id);
      _setStatus('Route Phoenix Mall → Koregaon Park (${olaPoints.length} pts)');
    } catch (e) {
      _setStatus('Route error: $e');
    }
  }

  Future<void> _goToMyLocation() async {
    await _controller?.showCurrentLocation();
    final location = await _controller?.getCurrentLocation();
    if (location == null) {
      _setStatus('Location unavailable');
      return;
    }
    await _controller!.zoomToLocation(location, 16);
    _setStatus('Your location');
  }

  Future<void> _resetScene() async {
    if (_controller == null) return;
    if (_zoneId != null) await _controller!.removePolygon(_zoneId!);
    if (_coverageId != null) await _controller!.removeCircle(_coverageId!);
    if (_tripLineId != null) await _controller!.removePolyline(_tripLineId!);
    if (_curveId != null) await _controller!.removeBezierCurve(_curveId!);
    if (_clusterId != null) await _controller!.removeClusteredMarkers(_clusterId!);
    if (_routeId != null) await _controller!.removePolyline(_routeId!);
    if (_droppedPinId != null) await _controller!.removeMarker(_droppedPinId!);
    setState(() {
      _zoneId = null;
      _coverageId = null;
      _tripLineId = null;
      _curveId = null;
      _clusterId = null;
      _routeId = null;
      _droppedPinId = null;
      _selectedPlace = null;
      _lastTap = null;
    });
    await _showPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPlace;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ola Maps Example'),
        actions: [
          IconButton(
            tooltip: 'Reset scene',
            onPressed: _mapReady ? _resetScene : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          OlaMapView(
            apiKey: kOlaMapsApiKey,
            initialCameraPosition: OlaMapsDemoData.mapCenter,
            initialZoom: OlaMapsDemoData.mapZoom,
            onMapError: _setStatus,
            onControllerReady: _onMapReady,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatusCard(
              status: _status,
              selectedPlace: selected,
              lastTap: _lastTap,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _RoundButton(
                  icon: Icons.add,
                  onPressed: _mapReady ? () => _controller!.zoomIn() : null,
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.remove,
                  onPressed: _mapReady ? () => _controller!.zoomOut() : null,
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.my_location,
                  onPressed: _mapReady ? _goToMyLocation : null,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 10,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                _LayerChip(
                  label: 'Places',
                  icon: Icons.place,
                  selected: _placeMarkerIds.isNotEmpty,
                  onPressed: _mapReady ? _showPlaces : null,
                ),
                _LayerChip(
                  label: 'Zone',
                  icon: Icons.hexagon_outlined,
                  selected: _zoneId != null,
                  onPressed: _mapReady ? _toggleDeliveryZone : null,
                ),
                _LayerChip(
                  label: 'Coverage',
                  icon: Icons.radar,
                  selected: _coverageId != null,
                  onPressed: _mapReady ? _toggleCoverage : null,
                ),
                _LayerChip(
                  label: 'Trip',
                  icon: Icons.alt_route,
                  selected: _tripLineId != null,
                  onPressed: _mapReady ? _toggleTripLine : null,
                ),
                _LayerChip(
                  label: 'Curve',
                  icon: Icons.trending_flat,
                  selected: _curveId != null,
                  onPressed: _mapReady ? _toggleBezier : null,
                ),
                _LayerChip(
                  label: 'Stores',
                  icon: Icons.bubble_chart,
                  selected: _clusterId != null,
                  onPressed: _mapReady ? _toggleClusters : null,
                ),
                _LayerChip(
                  label: 'Directions',
                  icon: Icons.navigation,
                  selected: _routeId != null,
                  onPressed: _mapReady ? _drawLiveRoute : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final DemoPlace? selectedPlace;
  final OlaLatLng? lastTap;

  const _StatusCard({
    required this.status,
    required this.selectedPlace,
    required this.lastTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedPlace?.title ?? 'Ola Maps · Pune demo',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedPlace?.subtitle ?? status,
              style: TextStyle(color: Colors.grey.shade700, height: 1.3),
            ),
            if (lastTap != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last tap  ${lastTap!.latitude.toStringAsFixed(5)}, ${lastTap!.longitude.toStringAsFixed(5)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  const _LayerChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: selected,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onSelected: onPressed == null ? null : (_) => onPressed!(),
        selectedColor: const Color(0xFFFBC02D),
        checkmarkColor: Colors.black,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: icon.codePoint.toString(),
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      child: Icon(icon),
    );
  }
}
