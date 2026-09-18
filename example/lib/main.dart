import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ola_maps/ola_maps.dart';
import 'package:permission_handler/permission_handler.dart';

import 'demo_data.dart';

const String kOlaMapsApiKey = String.fromEnvironment(
  'OLA_MAPS_API_KEY',
  defaultValue: 'YOUR_API_KEY',
);

const String kOlaMapsProjectId = String.fromEnvironment(
  'OLA_MAPS_PROJECT_ID',
  defaultValue: '',
);

const String kOlaMapsTileUrl = String.fromEnvironment(
  'OLA_MAPS_TILE_URL',
  defaultValue: kOlaMapsDefaultTileUrl,
);

const String kOlaMapsLanguage = String.fromEnvironment(
  'OLA_MAPS_LANGUAGE',
  defaultValue: 'en',
);

enum PinRole { drop, origin, destination }

void main() {
  if (isOlaMapsApiKeyConfigured(kOlaMapsApiKey)) {
    Olamaps.instance.initialize(
      kOlaMapsApiKey,
      language: kOlaMapsLanguage,
    );
  }
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
  final _searchController = TextEditingController();

  String _status = isOlaMapsApiKeyConfigured(kOlaMapsApiKey)
      ? 'Loading Pune demo scene…'
      : 'Pass --dart-define=OLA_MAPS_API_KEY=YOUR_KEY';

  DemoPlace? _selectedPlace;
  OlaLatLng? _lastTap;
  String? _pointerAddress;
  bool _pointerMode = true;
  bool _searching = false;

  PinRole _pinRole = PinRole.drop;
  double _coverageRadius = OlaMapsDemoData.coverageRadiusMeters;
  double _circleRadius = 600;
  String _routeMode = 'driving';
  bool _routeAlternatives = false;

  OlaLatLng _origin = OlaMapsDemoData.pickup.position;
  OlaLatLng _destination = OlaMapsDemoData.drop.position;
  String _originLabel = OlaMapsDemoData.pickup.title;
  String _destinationLabel = OlaMapsDemoData.drop.title;

  final List<String> _placeMarkerIds = [];
  String? _zoneId;
  String? _coverageId;
  String? _circleId;
  String? _tripLineId;
  String? _curveId;
  String? _clusterId;
  String? _routeId;
  String? _droppedPinId;
  String? _originMarkerId;
  String? _destMarkerId;

  Timer? _reverseGeocodeDebounce;

  bool get _mapReady => _controller != null;

  @override
  void initState() {
    super.initState();
    _routingService = OlaRoutingService(apiKey: kOlaMapsApiKey);
    if (!kIsWeb) {
      Permission.location.request();
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
    debugPrint(message);
  }

  Future<void> _onMapReady(OlaMapController controller) async {
    setState(() => _controller = controller);
    controller.onMapClick = _onMapTap;
    controller.onCameraIdle = _onCameraIdle;
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
    await _refreshEndpointMarkers();
    _setStatus('Move the pointer or search an address');
  }

  void _onCameraIdle(OlaLatLng position) {
    if (!_pointerMode) return;
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      _reverseGeocode(position, updatePointer: true);
    });
  }

  Future<void> _onMapTap(OlaLatLng position) async {
    setState(() {
      _lastTap = position;
      _pointerMode = false;
    });
    final address = await _reverseGeocode(position);
    await _applyPinnedLocation(position, address ?? 'Dropped pin');
  }

  Future<String?> _reverseGeocode(
    OlaLatLng position, {
    bool updatePointer = false,
  }) async {
    if (!isOlaMapsApiKeyConfigured(kOlaMapsApiKey)) return null;
    try {
      final results = await Olamaps.instance.geoencoder.fetchAddresses(
        Location(lat: position.latitude, lng: position.longitude),
      );
      final address = results.isEmpty
          ? '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
          : results.first.formattedAddress.isNotEmpty
              ? results.first.formattedAddress
              : results.first.name;
      if (!mounted) return address;
      setState(() {
        if (updatePointer) _pointerAddress = address;
        _status = address;
      });
      return address;
    } catch (e) {
      _setStatus('Reverse geocode failed: $e');
      return null;
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _controller == null) return;
    setState(() => _searching = true);
    try {
      final results = await Olamaps.instance.geoencoder.fetchLocation(query);
      if (results.isEmpty) {
        _setStatus('No geocode results for "$query"');
        return;
      }
      final hit = results.first;
      final position = OlaLatLng(
        hit.geometry.location.lat,
        hit.geometry.location.lng,
      );
      final label = hit.formattedAddress.isNotEmpty
          ? hit.formattedAddress
          : hit.name;
      await _controller!.zoomToLocation(position, 16);
      await _applyPinnedLocation(position, label);
      _setStatus('Geocoded: $label');
    } catch (e) {
      _setStatus('Geocode failed: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _applyPinnedLocation(OlaLatLng position, String label) async {
    switch (_pinRole) {
      case PinRole.drop:
        if (_droppedPinId != null) {
          await _controller?.removeMarker(_droppedPinId!);
        }
        final id = await _controller?.addMarker(
          markerId: 'dropped_pin',
          position: position,
          snippet: label,
          subSnippet:
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        );
        setState(() {
          _droppedPinId = id;
          _lastTap = position;
        });
      case PinRole.origin:
        setState(() {
          _origin = position;
          _originLabel = label;
        });
        await _refreshEndpointMarkers();
      case PinRole.destination:
        setState(() {
          _destination = position;
          _destinationLabel = label;
        });
        await _refreshEndpointMarkers();
    }
  }

  Future<void> _usePointerLocation() async {
    final camera = await _controller?.getCameraPosition();
    if (camera == null) return;
    final address = _pointerAddress ?? await _reverseGeocode(camera);
    await _applyPinnedLocation(camera, address ?? 'Pointer');
    _setStatus('Pinned from pointer · ${_pinRole.name}');
  }

  Future<void> _refreshEndpointMarkers() async {
    if (_controller == null) return;
    if (_originMarkerId != null) {
      await _controller!.removeMarker(_originMarkerId!);
    }
    if (_destMarkerId != null) {
      await _controller!.removeMarker(_destMarkerId!);
    }
    _originMarkerId = await _controller!.addMarker(
      markerId: 'route_origin',
      position: _origin,
      snippet: 'Origin',
      subSnippet: _originLabel,
    );
    _destMarkerId = await _controller!.addMarker(
      markerId: 'route_dest',
      position: _destination,
      snippet: 'Destination',
      subSnippet: _destinationLabel,
    );
    setState(() {});
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
    await _controller!.zoomToLocation(
      OlaMapsDemoData.headquarters.position,
      14.5,
    );
  }

  Future<void> _toggleCoverage({bool forceOn = false}) async {
    if (_controller == null) return;
    if (_coverageId != null && !forceOn) {
      await _controller!.removeCircle(_coverageId!);
      setState(() => _coverageId = null);
      _setStatus('Coverage hidden');
      return;
    }
    if (_coverageId != null) {
      await _controller!.updateCircle(
        circleId: _coverageId!,
        radius: _coverageRadius,
      );
      _setStatus('Coverage ${_coverageRadius.round()} m');
      return;
    }
    final center = await _controller!.getCameraPosition() ??
        OlaMapsDemoData.coverageCenter;
    final id = await _controller!.addCircle(
      circleId: 'hq_coverage',
      center: center,
      radius: _coverageRadius,
      color: '#2196F3',
      opacity: 0.25,
      borderColor: '#1565C0',
      borderWidth: 2,
    );
    setState(() => _coverageId = id);
    _setStatus('Coverage ${_coverageRadius.round()} m');
  }

  Future<void> _toggleCircle({bool forceOn = false}) async {
    if (_controller == null) return;
    if (_circleId != null && !forceOn) {
      await _controller!.removeCircle(_circleId!);
      setState(() => _circleId = null);
      _setStatus('Geofence hidden');
      return;
    }
    final center = _lastTap ??
        await _controller!.getCameraPosition() ??
        OlaMapsDemoData.headquarters.position;
    if (_circleId != null) {
      await _controller!.updateCircle(
        circleId: _circleId!,
        center: center,
        radius: _circleRadius,
      );
      _setStatus('Geofence ${_circleRadius.round()} m');
      return;
    }
    final id = await _controller!.addCircle(
      circleId: 'pointer_geofence',
      center: center,
      radius: _circleRadius,
      color: '#FF9800',
      opacity: 0.22,
      borderColor: '#E65100',
      borderWidth: 2,
    );
    setState(() => _circleId = id);
    _setStatus('Geofence ${_circleRadius.round()} m');
  }

  Future<void> _toggleTripLine() async {
    if (_controller == null) return;
    if (_tripLineId != null) {
      await _controller!.removePolyline(_tripLineId!);
      setState(() => _tripLineId = null);
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
  }

  Future<void> _toggleBezier() async {
    if (_controller == null) return;
    if (_curveId != null) {
      await _controller!.removeBezierCurve(_curveId!);
      setState(() => _curveId = null);
      return;
    }
    final id = await _controller!.addBezierCurve(
      curveId: 'pickup_to_drop',
      startPoint: _origin,
      endPoint: _destination,
      color: '#E53935',
      width: 4,
      lineType: OlaLineType.solid,
    );
    setState(() => _curveId = id);
  }

  Future<void> _toggleClusters() async {
    if (_controller == null) return;
    if (_clusterId != null) {
      await _controller!.removeClusteredMarkers(_clusterId!);
      setState(() => _clusterId = null);
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
  }

  Future<void> _drawLiveRoute() async {
    if (_controller == null) return;
    _setStatus('Fetching $_routeMode directions…');
    try {
      final routePoints = await _routingService.getDirections(
        originLat: _origin.latitude,
        originLng: _origin.longitude,
        destLat: _destination.latitude,
        destLng: _destination.longitude,
        mode: _routeMode,
        alternatives: _routeAlternatives,
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
      await _refreshEndpointMarkers();
      await _controller!.zoomToLocation(
        OlaLatLng(
          (_origin.latitude + _destination.latitude) / 2,
          (_origin.longitude + _destination.longitude) / 2,
        ),
        12.5,
      );
      setState(() => _routeId = id);
      _setStatus(
        '$_routeMode · $_originLabel → $_destinationLabel (${olaPoints.length} pts)',
      );
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
    final address = await _reverseGeocode(location, updatePointer: true);
    _setStatus(address ?? 'Your location');
  }

  Future<void> _resetScene() async {
    if (_controller == null) return;
    if (_zoneId != null) await _controller!.removePolygon(_zoneId!);
    if (_coverageId != null) await _controller!.removeCircle(_coverageId!);
    if (_circleId != null) await _controller!.removeCircle(_circleId!);
    if (_tripLineId != null) await _controller!.removePolyline(_tripLineId!);
    if (_curveId != null) await _controller!.removeBezierCurve(_curveId!);
    if (_clusterId != null) {
      await _controller!.removeClusteredMarkers(_clusterId!);
    }
    if (_routeId != null) await _controller!.removePolyline(_routeId!);
    if (_droppedPinId != null) await _controller!.removeMarker(_droppedPinId!);
    setState(() {
      _zoneId = null;
      _coverageId = null;
      _circleId = null;
      _tripLineId = null;
      _curveId = null;
      _clusterId = null;
      _routeId = null;
      _droppedPinId = null;
      _selectedPlace = null;
      _lastTap = null;
      _origin = OlaMapsDemoData.pickup.position;
      _destination = OlaMapsDemoData.drop.position;
      _originLabel = OlaMapsDemoData.pickup.title;
      _destinationLabel = OlaMapsDemoData.drop.title;
    });
    await _showPlaces();
    await _refreshEndpointMarkers();
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(VoidCallback fn) {
              setSheetState(fn);
              setState(fn);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Map settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pin action'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final role in PinRole.values)
                          ChoiceChip(
                            label: Text(switch (role) {
                              PinRole.drop => 'Drop pin',
                              PinRole.origin => 'Set origin',
                              PinRole.destination => 'Set destination',
                            }),
                            selected: _pinRole == role,
                            onSelected: (_) =>
                                update(() => _pinRole = role),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Center pointer'),
                      subtitle: const Text(
                        'Reverse-geocode the map center as you pan',
                      ),
                      value: _pointerMode,
                      onChanged: (value) =>
                          update(() => _pointerMode = value),
                    ),
                    const Divider(),
                    Text('Coverage radius  ${_coverageRadius.round()} m'),
                    Slider(
                      min: 200,
                      max: 5000,
                      divisions: 24,
                      value: _coverageRadius,
                      label: '${_coverageRadius.round()} m',
                      onChanged: (value) =>
                          update(() => _coverageRadius = value),
                      onChangeEnd: (_) {
                        if (_coverageId != null) {
                          _toggleCoverage(forceOn: true);
                        }
                      },
                    ),
                    Text('Circle / geofence radius  ${_circleRadius.round()} m'),
                    Slider(
                      min: 100,
                      max: 3000,
                      divisions: 29,
                      value: _circleRadius,
                      label: '${_circleRadius.round()} m',
                      onChanged: (value) =>
                          update(() => _circleRadius = value),
                      onChangeEnd: (_) {
                        if (_circleId != null) {
                          _toggleCircle(forceOn: true);
                        }
                      },
                    ),
                    const Divider(),
                    const Text('Directions'),
                    const SizedBox(height: 8),
                    Text(
                      'From  $_originLabel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      'To  $_destinationLabel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _routeMode,
                      decoration: const InputDecoration(
                        labelText: 'Travel mode',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'driving',
                          child: Text('Driving'),
                        ),
                        DropdownMenuItem(
                          value: 'bicycling',
                          child: Text('Bicycling'),
                        ),
                        DropdownMenuItem(
                          value: 'walking',
                          child: Text('Walking'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          update(() => _routeMode = value);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Request alternatives'),
                      value: _routeAlternatives,
                      onChanged: (value) =>
                          update(() => _routeAlternatives = value),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _drawLiveRoute();
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Draw route with these settings'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ola Maps Example'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
          ),
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
            tileUrl: kOlaMapsTileUrl,
            language: kOlaMapsLanguage,
            projectId: kOlaMapsProjectId,
            initialCameraPosition: OlaMapsDemoData.mapCenter,
            initialZoom: OlaMapsDemoData.mapZoom,
            onMapError: _setStatus,
            onControllerReady: _onMapReady,
          ),
          if (_pointerMode)
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Geocode an address…',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _searchAddress(),
                          ),
                        ),
                        if (_searching)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            onPressed: _searchAddress,
                            icon: const Icon(Icons.arrow_forward),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _StatusCard(
                  status: _status,
                  selectedPlace: _selectedPlace,
                  lastTap: _lastTap,
                  pointerAddress: _pointerAddress,
                  originLabel: _originLabel,
                  destinationLabel: _destinationLabel,
                  pinRole: _pinRole,
                ),
              ],
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
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.push_pin,
                  onPressed: _mapReady && _pointerMode
                      ? _usePointerLocation
                      : null,
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
                  label: 'Circle',
                  icon: Icons.circle_outlined,
                  selected: _circleId != null,
                  onPressed: _mapReady ? _toggleCircle : null,
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
  final String? pointerAddress;
  final String originLabel;
  final String destinationLabel;
  final PinRole pinRole;

  const _StatusCard({
    required this.status,
    required this.selectedPlace,
    required this.lastTap,
    required this.pointerAddress,
    required this.originLabel,
    required this.destinationLabel,
    required this.pinRole,
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
              pointerAddress ?? selectedPlace?.subtitle ?? status,
              style: TextStyle(color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Pin → ${pinRole.name}   ·   $originLabel → $destinationLabel',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (lastTap != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last tap  ${lastTap!.latitude.toStringAsFixed(5)}, ${lastTap!.longitude.toStringAsFixed(5)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
