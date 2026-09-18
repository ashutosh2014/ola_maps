// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:ola_maps/src/web/ola_maps_js.dart';
import 'package:web/web.dart' as web;

/// Browser host for [Ola Maps Web SDK v2](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup).
class OlaMapsWebHost {
  OlaMapsWebHost(this.viewId, this.element) {
    _hosts[viewId] = this;
  }

  final int viewId;
  final web.HTMLDivElement element;
  Future<dynamic> Function(MethodCall call)? eventHandler;

  static final Map<int, OlaMapsWebHost> _hosts = {};

  static OlaMapsWebHost? get(int id) => _hosts[id];

  JSObject? _client;
  JSObject? _map;
  JSObject? _geolocate;
  JSObject? _navControl;
  web.ResizeObserver? _resizeObserver;
  Completer<void>? _ready;
  Object? _loadError;
  bool _disposed = false;

  final Map<String, _WebMarker> _markers = {};
  final Map<String, _OverlayIds> _overlays = {};
  Map<String, Object?>? _lastLocation;

  Future<dynamic> handle(String method, dynamic arguments) async {
    final args = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : <String, dynamic>{};
    switch (method) {
      case 'initialize':
        await _initialize(args);
        return null;
      case 'waitUntilMapReady':
        await _waitReady();
        return null;
      case 'addMarker':
        return _addMarker(args);
      case 'removeMarker':
        _markers.remove(args['markerId']?.toString())?.remove();
        return null;
      case 'updateMarker':
        _updateMarker(args);
        return null;
      case 'showInfoWindow':
        _markers[args['markerId']?.toString()]?.showPopup();
        return null;
      case 'hideInfoWindow':
        _markers[args['markerId']?.toString()]?.hidePopup();
        return null;
      case 'updateInfoWindow':
        _markers[args['markerId']?.toString()]
            ?.updatePopup(args['text']?.toString() ?? '');
        return null;
      case 'addPolyline':
        return _addLine(args, bezier: false);
      case 'removePolyline':
        _removeOverlay(args['polylineId']?.toString());
        return null;
      case 'updatePolyline':
        _updateLine(args, bezier: false);
        return null;
      case 'addCircle':
        return _addCircle(args);
      case 'removeCircle':
        _removeOverlay(args['circleId']?.toString());
        return null;
      case 'updateCircle':
        _updateCircle(args);
        return null;
      case 'addPolygon':
        return _addPolygon(args);
      case 'removePolygon':
        _removeOverlay(args['polygonId']?.toString());
        return null;
      case 'updatePolygon':
        _updatePolygon(args);
        return null;
      case 'addBezierCurve':
        return _addLine(args, bezier: true);
      case 'removeBezierCurve':
        _removeOverlay(args['curveId']?.toString());
        return null;
      case 'updateBezierCurve':
        _updateLine(args, bezier: true);
        return null;
      case 'zoomToLocation':
      case 'moveCamera':
        _easeTo(
          lat: _double(args['latitude']),
          lng: _double(args['longitude']),
          zoom: _double(args['zoomLevel']),
          durationMs: _int(args['durationMs']) ?? 500,
        );
        return null;
      case 'zoomIn':
        _zoomBy(1);
        return null;
      case 'zoomOut':
        _zoomBy(-1);
        return null;
      case 'getCurrentLocation':
        return _lastLocation ?? await _browserLocation();
      case 'getCameraPosition':
        return _cameraPosition();
      case 'showCurrentLocation':
        _setGeolocate(true);
        return null;
      case 'hideCurrentLocation':
        _setGeolocate(false);
        return null;
      case 'addClusteredMarkers':
        return _addCluster(args);
      case 'updateClusteredMarkers':
        _updateCluster(args);
        return null;
      case 'removeClusteredMarkers':
        _removeOverlay(args['clusterId']?.toString());
        return null;
      case 'dispose':
        dispose();
        return null;
      default:
        throw MissingPluginException(method);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _resizeObserver?.disconnect();
    _resizeObserver = null;
    for (final marker in _markers.values) {
      marker.remove();
    }
    _markers.clear();
    for (final id in _overlays.keys.toList()) {
      _removeOverlay(id);
    }
    try {
      _map?.callMethod('remove'.toJS);
    } catch (_) {}
    _map = null;
    _client = null;
    _hosts.remove(viewId);
  }

  Future<void> _initialize(Map<String, dynamic> args) async {
    _ready = Completer<void>();
    _loadError = null;
    await ensureOlaMapsWebSdkLoaded();
    if (_disposed) return;

    final apiKey = args['apiKey']?.toString() ?? '';
    final tileUrl = args['tileUrl']?.toString() ??
        'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json';
    final lat = _double(args['initialLatitude']) ?? 12.931423492103944;
    final lng = _double(args['initialLongitude']) ?? 77.61648476788898;
    final zoom = _double(args['initialZoom']) ?? 15;
    final mode3d = args['mode3d'] == true;
    final tileset = args['threeDTileset']?.toString();

    element
      ..id = 'ola-map-view-$viewId'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'relative';

    try {
      _map?.callMethod('remove'.toJS);
    } catch (_) {}

    _client = constructOlaMaps({
      'apiKey': apiKey,
      if (mode3d) 'mode': '3d',
      if (mode3d)
        'threedTileset': tileset ??
            'https://api.olamaps.io/tiles/vector/v1/3dtiles/tileset.json',
    });

    final initOptions = jsObject({
      'style': tileUrl,
      'center': [lng, lat],
      'zoom': zoom,
    });
    initOptions.setProperty('container'.toJS, element);
    final init = _client!.callMethod('init'.toJS, initOptions);
    final resolved = await awaitJs(init as JSAny?);
    _map = asJsObject(resolved);
    if (_map == null) {
      throw StateError('OlaMaps.init did not return a map');
    }

    _bindMapEvents();
    _applyGestures(args);
    _addNavigation(args);
    if (args['myLocationEnabled'] == true ||
        args['showMyLocationButton'] == true) {
      _setGeolocate(true, trigger: args['myLocationEnabled'] == true);
    }
    _observeResize();
  }

  Future<void> _waitReady() async {
    if (_loadError != null) {
      throw PlatformException(code: 'MAP_ERROR', message: _loadError.toString());
    }
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      await ready.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw PlatformException(
            code: 'MAP_TIMEOUT',
            message: 'Timed out waiting for Ola Maps Web SDK',
          );
        },
      );
    }
    if (_loadError != null) {
      throw PlatformException(code: 'MAP_ERROR', message: _loadError.toString());
    }
  }

  void _bindMapEvents() {
    final map = _map!;
    _on(map, 'load', (_) {
      if (_ready != null && !_ready!.isCompleted) _ready!.complete();
      _emit('onMapReady', null);
      map.callMethod('resize'.toJS);
    });
    _on(map, 'fail', (event) {
      final message = event?.toString() ?? 'Ola Maps failed to load';
      _loadError = message;
      if (_ready != null && !_ready!.isCompleted) _ready!.complete();
      _emit('onMapError', message);
    });
    _on(map, 'error', (event) {
      final message = jsString(event?.getProperty('error'.toJS)) ??
          jsString(event?.getProperty('message'.toJS));
      if (message != null && message.contains('403')) {
        _loadError = message;
        if (_ready != null && !_ready!.isCompleted) _ready!.complete();
        _emit('onMapError', message);
      }
    });
    void emitClick(JSObject? event, String method) {
      final point = _lngLat(event);
      if (point != null) _emit(method, point);
    }

    _on(map, 'click', (event) => emitClick(event, 'onMapClick'));
    _on(map, 'contextmenu', (event) => emitClick(event, 'onMapLongClick'));
    _on(map, 'idle', (_) {
      final camera = _cameraPosition();
      if (camera != null) {
        _emit('onCameraIdle', camera);
      }
    });
  }

  void _applyGestures(Map<String, dynamic> args) {
    final map = _map!;
    void setEnabled(String handler, bool enabled) {
      final target = asJsObject(map.getProperty(handler.toJS));
      target?.callMethod((enabled ? 'enable' : 'disable').toJS);
    }

    setEnabled('dragRotate', args['rotateGesturesEnabled'] != false);
    setEnabled('dragPan', args['scrollGesturesEnabled'] != false);
    setEnabled('scrollZoom', args['zoomGesturesEnabled'] != false);
    setEnabled('boxZoom', args['zoomGesturesEnabled'] != false);
    setEnabled('doubleClickZoom', args['doubleTapGesturesEnabled'] != false);
    setEnabled('touchPitch', args['tiltGesturesEnabled'] != false);
    final rotate = asJsObject(map.getProperty('touchZoomRotate'.toJS));
    if (args['rotateGesturesEnabled'] == false) {
      rotate?.callMethod('disableRotation'.toJS);
    }
  }

  void _addNavigation(Map<String, dynamic> args) {
    final showCompass = args['showCompass'] != false;
    final showZoom = args['showZoomControls'] != false;
    if (!showCompass && !showZoom) return;
    try {
      final control = _client!.callMethod(
        'addNavigationControls'.toJS,
        jsObject({
          'showCompass': showCompass,
          'showZoom': showZoom,
          'visualizePitch': false,
        }),
      );
      _navControl = asJsObject(control as JSAny?);
      if (_navControl != null) {
        _map!.callMethod('addControl'.toJS, _navControl);
      }
    } catch (_) {
      try {
        final ctor = olaMapsCtor()?.getProperty('NavigationControl'.toJS);
        if (ctor.isA<JSFunction>()) {
          _navControl = (ctor as JSFunction).callAsConstructor(
            jsObject({
              'showCompass': showCompass,
              'showZoom': showZoom,
              'visualizePitch': false,
            }),
          ) as JSObject;
          _map!.callMethod('addControl'.toJS, _navControl);
        }
      } catch (_) {}
    }
  }

  void _setGeolocate(bool enabled, {bool trigger = true}) {
    final map = _map;
    if (map == null || _client == null) return;
    if (!enabled) {
      if (_geolocate != null) {
        try {
          map.callMethod('removeControl'.toJS, _geolocate);
        } catch (_) {}
        _geolocate = null;
      }
      return;
    }
    if (_geolocate != null) {
      if (trigger) {
        try {
          _geolocate!.callMethod('trigger'.toJS);
        } catch (_) {}
      }
      return;
    }
    try {
      final control = _client!.callMethod(
        'addGeolocateControls'.toJS,
        jsObject({
          'positionOptions': {'enableHighAccuracy': true},
          'trackUserLocation': true,
          'showUserLocation': true,
        }),
      );
      _geolocate = asJsObject(control as JSAny?);
      if (_geolocate != null) {
        try {
          map.callMethod('addControl'.toJS, _geolocate);
        } catch (_) {}
        _on(_geolocate!, 'geolocate', (event) {
          final coords = asJsObject(event?.getProperty('coords'.toJS));
          final lat = jsNum(coords?.getProperty('latitude'.toJS));
          final lng = jsNum(coords?.getProperty('longitude'.toJS));
          if (lat != null && lng != null) {
            _lastLocation = {
              'latitude': lat.toDouble(),
              'longitude': lng.toDouble(),
            };
          }
        });
        if (trigger) {
          try {
            _geolocate!.callMethod('trigger'.toJS);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _observeResize() {
    _resizeObserver?.disconnect();
    _resizeObserver = web.ResizeObserver(
      (JSArray<web.ResizeObserverEntry> _, web.ResizeObserver __) {
        _map?.callMethod('resize'.toJS);
      }.toJS,
    );
    _resizeObserver!.observe(element);
  }

  String _addMarker(Map<String, dynamic> args) {
    final id = args['markerId']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final lat = _double(args['latitude']) ?? 0;
    final lng = _double(args['longitude']) ?? 0;
    final options = <String, Object?>{
      'anchor': args['iconAnchor'] ?? 'bottom',
      if (args['iconOffset'] is List)
        'offset': [
          for (final value in args['iconOffset'] as List)
            (value as num).toDouble(),
        ],
    };
    final iconPath = args['iconPath']?.toString();
    if (iconPath != null && iconPath.isNotEmpty) {
      final img = web.HTMLImageElement()
        ..src = iconPath
        ..style.width = '${_double(args['iconSize']) ?? 32}px';
      options['element'] = img;
    }
    JSObject marker;
    try {
      marker = asJsObject(
        _client!.callMethod('addMarker'.toJS, jsObject(options)) as JSAny?,
      )!;
    } catch (_) {
      final ctor = olaMapsCtor()?.getProperty('Marker'.toJS);
      marker = (ctor as JSFunction).callAsConstructor(jsObject(options))
          as JSObject;
    }
    marker.callMethod('setLngLat'.toJS, jsValue([lng, lat]));
    marker.callMethod('addTo'.toJS, _map);

    final rotation = _double(args['iconRotation']);
    if (rotation != null) {
      marker.callMethod('setRotation'.toJS, rotation.toJS);
    }

    final snippet = [
      args['snippet']?.toString(),
      args['subSnippet']?.toString(),
    ].whereType<String>().where((text) => text.isNotEmpty).join('\n');

    JSObject? popup;
    if (snippet.isNotEmpty) {
      popup = _createPopup(snippet);
      marker.callMethod('setPopup'.toJS, popup);
    }

    final element = asJsObject(marker.callMethod('getElement'.toJS) as JSAny?);
    element?.callMethod(
      'addEventListener'.toJS,
      'click'.toJS,
      ((web.Event event) {
        event.stopPropagation();
        _emit('onMarkerClick', {'markerId': id});
      }).toJS,
    );

    _markers[id]?.remove();
    _markers[id] = _WebMarker(marker, popup, snippet);
    return id;
  }

  void _updateMarker(Map<String, dynamic> args) {
    final marker = _markers[args['markerId']?.toString()];
    if (marker == null) return;
    final lat = _double(args['latitude']);
    final lng = _double(args['longitude']);
    if (lat != null && lng != null) {
      marker.js.callMethod('setLngLat'.toJS, jsValue([lng, lat]));
    }
    final rotation = _double(args['iconRotation']);
    if (rotation != null) {
      marker.js.callMethod('setRotation'.toJS, rotation.toJS);
    }
    if (args.containsKey('snippet') || args.containsKey('subSnippet')) {
      final snippet = [
        args['snippet']?.toString(),
        args['subSnippet']?.toString(),
      ].whereType<String>().where((text) => text.isNotEmpty).join('\n');
      marker.updatePopup(snippet);
    }
  }

  JSObject _createPopup(String text) {
    JSObject popup;
    try {
      popup = asJsObject(
        _client!.callMethod(
          'addPopup'.toJS,
          jsObject({'offset': 24, 'anchor': 'bottom'}),
        ) as JSAny?,
      )!;
    } catch (_) {
      final ctor = olaMapsCtor()?.getProperty('Popup'.toJS);
      popup = (ctor as JSFunction).callAsConstructor(
        jsObject({'offset': 24, 'anchor': 'bottom'}),
      ) as JSObject;
    }
    popup.callMethod('setText'.toJS, text.toJS);
    return popup;
  }

  String _addLine(Map<String, dynamic> args, {required bool bezier}) {
    final id = (bezier ? args['curveId'] : args['polylineId'])?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final coordinates = bezier ? _bezierCoords(args) : _lineCoords(args);
    _putOverlay(
      id: id,
      geoJson: _lineGeoJson(coordinates),
      lineColor: args['color']?.toString() ?? '#1976D2',
      lineWidth: _double(args['width']) ?? 4,
      dashed: args['lineType']?.toString() == 'LINE_DOTTED',
    );
    return id;
  }

  void _updateLine(Map<String, dynamic> args, {required bool bezier}) {
    final id = (bezier ? args['curveId'] : args['polylineId'])?.toString();
    if (id == null) return;
    final existing = _overlays[id];
    if (existing == null) return;
    final coordinates = bezier
        ? (args.containsKey('startLatitude') ? _bezierCoords(args) : existing.coordinates)
        : (args['points'] != null ? _lineCoords(args) : existing.coordinates);
    _putOverlay(
      id: id,
      geoJson: _lineGeoJson(coordinates),
      lineColor: args['color']?.toString() ?? existing.lineColor,
      lineWidth: _double(args['width']) ?? existing.lineWidth,
      dashed: args['lineType'] != null
          ? args['lineType']?.toString() == 'LINE_DOTTED'
          : existing.dashed,
    );
  }

  String _addCircle(Map<String, dynamic> args) {
    final id = args['circleId']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    _putOverlay(
      id: id,
      geoJson: _circleGeoJson(args),
      fillColor: args['color']?.toString() ?? '#2196F3',
      fillOpacity: _double(args['opacity']) ?? 0.3,
      lineColor: args['borderColor']?.toString() ??
          args['color']?.toString() ??
          '#2196F3',
      lineWidth: _double(args['borderWidth']) ?? 2,
      dashed: args['borderLineType']?.toString() == 'LINE_DOTTED',
    );
    return id;
  }

  void _updateCircle(Map<String, dynamic> args) {
    final id = args['circleId']?.toString();
    if (id == null) return;
    final existing = _overlays[id];
    if (existing == null) return;
    _putOverlay(
      id: id,
      geoJson: args.containsKey('latitude') || args.containsKey('radius')
          ? _circleGeoJson({...existing.args, ...args})
          : existing.geoJson,
      fillColor: args['color']?.toString() ?? existing.fillColor,
      fillOpacity: _double(args['opacity']) ?? existing.fillOpacity,
      lineColor: args['borderColor']?.toString() ?? existing.lineColor,
      lineWidth: _double(args['borderWidth']) ?? existing.lineWidth,
      dashed: args['borderLineType'] != null
          ? args['borderLineType']?.toString() == 'LINE_DOTTED'
          : existing.dashed,
      args: {...existing.args, ...args},
    );
  }

  String _addPolygon(Map<String, dynamic> args) {
    final id = args['polygonId']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    _putOverlay(
      id: id,
      geoJson: _polygonGeoJson(_lineCoords(args)),
      fillColor: args['color']?.toString() ?? '#4CAF50',
      fillOpacity: 0.35,
      lineColor: args['borderColor']?.toString() ?? '#388E3C',
      lineWidth: _double(args['borderWidth']) ?? 2,
      dashed: args['borderLineType']?.toString() == 'LINE_DOTTED',
    );
    return id;
  }

  void _updatePolygon(Map<String, dynamic> args) {
    final id = args['polygonId']?.toString();
    if (id == null) return;
    final existing = _overlays[id];
    if (existing == null) return;
    final coords =
        args['points'] != null ? _lineCoords(args) : existing.coordinates;
    _putOverlay(
      id: id,
      geoJson: _polygonGeoJson(coords),
      fillColor: args['color']?.toString() ?? existing.fillColor,
      fillOpacity: existing.fillOpacity,
      lineColor: args['borderColor']?.toString() ?? existing.lineColor,
      lineWidth: _double(args['borderWidth']) ?? existing.lineWidth,
      dashed: args['borderLineType'] != null
          ? args['borderLineType']?.toString() == 'LINE_DOTTED'
          : existing.dashed,
    );
  }

  String _addCluster(Map<String, dynamic> args) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _putCluster(id, args);
    return id;
  }

  void _updateCluster(Map<String, dynamic> args) {
    final id = args['clusterId']?.toString();
    if (id == null) return;
    _putCluster(id, args);
  }

  void _putCluster(String id, Map<String, dynamic> args) {
    final geoJson = _decodeGeoJson(args['geoJson']?.toString() ?? '{}');
    final radius = _int(args['clusterRadius']) ?? 50;
    final color = args['defaultClusterColor']?.toString() ?? '#00AA00';
    final markerColor = args['defaultMarkerColor']?.toString() ?? '#FF0000';
    _removeOverlay(id);
    final source = 'src-$id';
    _map!.callMethod(
      'addSource'.toJS,
      source.toJS,
      jsObject({
        'type': 'geojson',
        'data': geoJson,
        'cluster': true,
        'clusterRadius': radius,
      }),
    );
    _map!.callMethod(
      'addLayer'.toJS,
      jsObject({
        'id': 'cluster-$id',
        'type': 'circle',
        'source': source,
        'filter': ['has', 'point_count'],
        'paint': {
          'circle-color': color,
          'circle-radius': 18,
        },
      }),
    );
    _map!.callMethod(
      'addLayer'.toJS,
      jsObject({
        'id': 'count-$id',
        'type': 'symbol',
        'source': source,
        'filter': ['has', 'point_count'],
        'layout': {
          'text-field': '{point_count_abbreviated}',
          'text-size': _double(args['textSize']) ?? 12,
        },
        'paint': {
          'text-color': args['textColor']?.toString() ?? '#FFFFFF',
        },
      }),
    );
    _map!.callMethod(
      'addLayer'.toJS,
      jsObject({
        'id': 'point-$id',
        'type': 'circle',
        'source': source,
        'filter': ['!', ['has', 'point_count']],
        'paint': {
          'circle-color': markerColor,
          'circle-radius': 7,
        },
      }),
    );
    _overlays[id] = _OverlayIds(
      source: source,
      layers: ['cluster-$id', 'count-$id', 'point-$id'],
      geoJson: geoJson,
    );
  }

  void _putOverlay({
    required String id,
    required Map<String, Object?> geoJson,
    String? fillColor,
    double fillOpacity = 0.3,
    String? lineColor,
    double lineWidth = 3,
    bool dashed = false,
    Map<String, dynamic>? args,
  }) {
    final existing = _overlays[id];
    if (existing != null) {
      final source = asJsObject(
        _map!.callMethod('getSource'.toJS, existing.source.toJS) as JSAny?,
      );
      source?.callMethod('setData'.toJS, jsObject(geoJson));
      _overlays[id] = existing.copyWith(
        geoJson: geoJson,
        fillColor: fillColor,
        fillOpacity: fillOpacity,
        lineColor: lineColor,
        lineWidth: lineWidth,
        dashed: dashed,
        args: args,
      );
      return;
    }
    final source = 'src-$id';
    _map!.callMethod(
      'addSource'.toJS,
      source.toJS,
      jsObject({'type': 'geojson', 'data': geoJson}),
    );
    final layers = <String>[];
    final geometry = (geoJson['geometry'] as Map?)?['type']?.toString();
    if (geometry == 'Polygon') {
      _map!.callMethod(
        'addLayer'.toJS,
        jsObject({
          'id': 'fill-$id',
          'type': 'fill',
          'source': source,
          'paint': {
            'fill-color': fillColor ?? '#2196F3',
            'fill-opacity': fillOpacity,
          },
        }),
      );
      layers.add('fill-$id');
    }
    _map!.callMethod(
      'addLayer'.toJS,
      jsObject({
        'id': 'line-$id',
        'type': 'line',
        'source': source,
        'paint': {
          'line-color': lineColor ?? fillColor ?? '#1976D2',
          'line-width': lineWidth,
          if (dashed) 'line-dasharray': [2, 2],
        },
      }),
    );
    layers.add('line-$id');
    _overlays[id] = _OverlayIds(
      source: source,
      layers: layers,
      geoJson: geoJson,
      fillColor: fillColor,
      fillOpacity: fillOpacity,
      lineColor: lineColor,
      lineWidth: lineWidth,
      dashed: dashed,
      args: args ?? const {},
    );
  }

  void _removeOverlay(String? id) {
    if (id == null) return;
    final overlay = _overlays.remove(id);
    if (overlay == null || _map == null) return;
    for (final layer in overlay.layers) {
      try {
        _map!.callMethod('removeLayer'.toJS, layer.toJS);
      } catch (_) {}
    }
    try {
      _map!.callMethod('removeSource'.toJS, overlay.source.toJS);
    } catch (_) {}
  }

  void _easeTo({
    double? lat,
    double? lng,
    double? zoom,
    int durationMs = 500,
  }) {
    final camera = <String, Object?>{
      if (lat != null && lng != null) 'center': [lng, lat],
      if (zoom != null) 'zoom': zoom,
      'duration': durationMs,
    };
    _map?.callMethod('easeTo'.toJS, jsObject(camera));
  }

  void _zoomBy(num delta) {
    final zoom = jsNum(_map?.callMethod('getZoom'.toJS) as JSAny?) ?? 15;
    _map?.callMethod(
      'easeTo'.toJS,
      jsObject({'zoom': zoom.toDouble() + delta, 'duration': 250}),
    );
  }

  Map<String, Object?>? _cameraPosition() {
    final map = _map;
    if (map == null) return null;
    final center = asJsObject(map.callMethod('getCenter'.toJS) as JSAny?);
    final lat = jsNum(center?.getProperty('lat'.toJS));
    final lng = jsNum(center?.getProperty('lng'.toJS));
    if (lat == null || lng == null) return null;
    return {
      'latitude': lat.toDouble(),
      'longitude': lng.toDouble(),
      'zoom': jsNum(map.callMethod('getZoom'.toJS) as JSAny?)?.toDouble() ?? 0,
      'bearing':
          jsNum(map.callMethod('getBearing'.toJS) as JSAny?)?.toDouble() ?? 0,
      'tilt': jsNum(map.callMethod('getPitch'.toJS) as JSAny?)?.toDouble() ?? 0,
    };
  }

  Future<Map<String, Object?>?> _browserLocation() async {
    final completer = Completer<Map<String, Object?>?>();
    try {
      web.window.navigator.geolocation.getCurrentPosition(
        (web.GeolocationPosition position) {
          final coords = position.coords;
          completer.complete({
            'latitude': coords.latitude,
            'longitude': coords.longitude,
          });
        }.toJS,
        (web.GeolocationPositionError _) {
          completer.complete(null);
        }.toJS,
      );
    } catch (_) {
      return _lastLocation;
    }
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => _lastLocation,
    );
  }

  void _on(
    JSObject target,
    String event,
    void Function(JSObject? event) handler,
  ) {
    target.callMethod(
      'on'.toJS,
      event.toJS,
      ((JSAny? raw) {
        handler(asJsObject(raw));
      }).toJS,
    );
  }

  Map<String, Object?>? _lngLat(JSObject? event) {
    final lngLat = asJsObject(event?.getProperty('lngLat'.toJS));
    final lat = jsNum(lngLat?.getProperty('lat'.toJS));
    final lng = jsNum(lngLat?.getProperty('lng'.toJS));
    if (lat == null || lng == null) return null;
    return {
      'latitude': lat.toDouble(),
      'longitude': lng.toDouble(),
    };
  }

  void _emit(String method, dynamic arguments) {
    eventHandler?.call(MethodCall(method, arguments));
  }

  List<List<double>> _lineCoords(Map<String, dynamic> args) {
    final points = args['points'];
    if (points is! List) return const [];
    return [
      for (final point in points)
        if (point is Map)
          [
            (point['longitude'] as num).toDouble(),
            (point['latitude'] as num).toDouble(),
          ],
    ];
  }

  List<List<double>> _bezierCoords(Map<String, dynamic> args) {
    final start = [
      _double(args['startLongitude']) ?? 0,
      _double(args['startLatitude']) ?? 0,
    ];
    final end = [
      _double(args['endLongitude']) ?? 0,
      _double(args['endLatitude']) ?? 0,
    ];
    final midX = (start[0] + end[0]) / 2;
    final midY = (start[1] + end[1]) / 2;
    final dx = end[0] - start[0];
    final dy = end[1] - start[1];
    final control = [midX - dy * 0.25, midY + dx * 0.25];
    return [
      for (var i = 0; i <= 32; i++)
        _quad(start, control, end, i / 32),
    ];
  }

  List<double> _quad(
    List<double> p0,
    List<double> p1,
    List<double> p2,
    double t,
  ) {
    final mt = 1 - t;
    return [
      mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0],
      mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1],
    ];
  }

  Map<String, Object?> _lineGeoJson(List<List<double>> coordinates) {
    return {
      'type': 'Feature',
      'properties': <String, Object?>{},
      'geometry': {
        'type': 'LineString',
        'coordinates': coordinates,
      },
    };
  }

  Map<String, Object?> _polygonGeoJson(List<List<double>> coordinates) {
    final ring = [...coordinates];
    if (ring.isNotEmpty &&
        (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add(ring.first);
    }
    return {
      'type': 'Feature',
      'properties': <String, Object?>{},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [ring],
      },
    };
  }

  Map<String, Object?> _circleGeoJson(Map<String, dynamic> args) {
    final lat = _double(args['latitude']) ?? 0;
    final lng = _double(args['longitude']) ?? 0;
    final radius = _double(args['radius']) ?? 100;
    const steps = 64;
    final latRad = lat * math.pi / 180;
    final metersPerLat = 110540.0;
    final metersPerLng = 111320.0 * math.cos(latRad);
    final ring = <List<double>>[
      for (var i = 0; i <= steps; i++)
        [
          lng + (radius * math.cos(2 * math.pi * i / steps)) / metersPerLng,
          lat + (radius * math.sin(2 * math.pi * i / steps)) / metersPerLat,
        ],
    ];
    return _polygonGeoJson(ring);
  }

  Map<String, Object?> _decodeGeoJson(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } catch (_) {}
    return {
      'type': 'FeatureCollection',
      'features': <Object?>[],
    };
  }

  double? _double(dynamic value) =>
      value is num ? value.toDouble() : num.tryParse('$value')?.toDouble();

  int? _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}

class _WebMarker {
  _WebMarker(this.js, this.popup, this.text);

  final JSObject js;
  JSObject? popup;
  String text;

  void showPopup() {
    try {
      final current =
          popup ?? asJsObject(js.callMethod('getPopup'.toJS) as JSAny?);
      if (current == null) return;
      final open = current.callMethod('isOpen'.toJS);
      if (open.isA<JSBoolean>() && (open as JSBoolean).toDart) return;
      js.callMethod('togglePopup'.toJS);
    } catch (_) {}
  }

  void hidePopup() {
    try {
      popup?.callMethod('remove'.toJS);
    } catch (_) {}
  }

  void updatePopup(String value) {
    text = value;
    if (value.isEmpty) {
      hidePopup();
      return;
    }
    popup ??= asJsObject(js.callMethod('getPopup'.toJS) as JSAny?);
    popup?.callMethod('setText'.toJS, value.toJS);
  }

  void remove() {
    try {
      js.callMethod('remove'.toJS);
    } catch (_) {}
  }
}

class _OverlayIds {
  _OverlayIds({
    required this.source,
    required this.layers,
    required this.geoJson,
    this.fillColor,
    this.fillOpacity = 0.3,
    this.lineColor,
    this.lineWidth = 3,
    this.dashed = false,
    this.args = const {},
  });

  final String source;
  final List<String> layers;
  final Map<String, Object?> geoJson;
  final String? fillColor;
  final double fillOpacity;
  final String? lineColor;
  final double lineWidth;
  final bool dashed;
  final Map<String, dynamic> args;

  List<List<double>> get coordinates {
    final geometry = geoJson['geometry'];
    if (geometry is! Map) return const [];
    final coords = geometry['coordinates'];
    if (geometry['type'] == 'Polygon' && coords is List && coords.isNotEmpty) {
      return [
        for (final point in coords.first as List)
          if (point is List && point.length >= 2)
            [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
      ];
    }
    if (coords is List) {
      return [
        for (final point in coords)
          if (point is List && point.length >= 2)
            [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
      ];
    }
    return const [];
  }

  _OverlayIds copyWith({
    Map<String, Object?>? geoJson,
    String? fillColor,
    double? fillOpacity,
    String? lineColor,
    double? lineWidth,
    bool? dashed,
    Map<String, dynamic>? args,
  }) {
    return _OverlayIds(
      source: source,
      layers: layers,
      geoJson: geoJson ?? this.geoJson,
      fillColor: fillColor ?? this.fillColor,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashed: dashed ?? this.dashed,
      args: args ?? this.args,
    );
  }
}
