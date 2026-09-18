import CoreLocation
import Flutter
import OlaMapCore
import UIKit

final class OlaMapPlatformView: NSObject, FlutterPlatformView, OlaMapServiceDelegate, CLLocationManagerDelegate {
  private let container = UIView()
  private let viewId: Int64
  private let messenger: FlutterBinaryMessenger
  private let registrar: FlutterPluginRegistrar
  private let methodChannel: FlutterMethodChannel
  private let cameraChannel: FlutterEventChannel
  private var cameraEvents: FlutterEventSink?

  private var olaMap: OlaMapService?
  private var isMapReady = false
  private var mapError: String?
  private var pendingReadyResult: FlutterResult?
  private var lastZoom: Double = 15
  private var lastCoordinate: OlaCoordinate?
  private var showsUserLocation = false
  private var locationButtonAdded = false

  private var markers: [String: MarkerRecord] = [:]
  private var polylines: [String: OverlayRecord] = [:]
  private var polygons: [String: OverlayRecord] = [:]
  private var circles: [String: OverlayRecord] = [:]
  private var bezierCurves: [String: OverlayRecord] = [:]
  private var clusters: [String: [String]] = [:]

  private let locationManager = CLLocationManager()
  private var lastDeviceLocation: CLLocation?

  init(
    frame: CGRect,
    viewId: Int64,
    args: [String: Any]?,
    messenger: FlutterBinaryMessenger,
    registrar: FlutterPluginRegistrar
  ) {
    self.viewId = viewId
    self.messenger = messenger
    self.registrar = registrar
    self.methodChannel = FlutterMethodChannel(
      name: "ola_map_view_flutter_\(viewId)",
      binaryMessenger: messenger
    )
    self.cameraChannel = FlutterEventChannel(
      name: "ola_map_view_flutter_camera_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    container.frame = frame
    container.clipsToBounds = true
    container.backgroundColor = UIColor.systemGray6

    methodChannel.setMethodCallHandler(handle)
    cameraChannel.setStreamHandler(CameraStreamHandler { [weak self] sink in
      self?.cameraEvents = sink
    })

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest

    initializeMap(args: args)
  }

  func view() -> UIView {
    container
  }

  private func initializeMap(args: [String: Any]?) {
    let apiKey = FlutterArgs.string(args, "apiKey")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if apiKey.isEmpty || apiKey == "YOUR_API_KEY" || apiKey == "YOUR_OLA_MAPS_API_KEY" {
      notifyMapError("loading style failed: HTTP status code 403 (missing Ola Maps API key)")
      return
    }

    let tileURL = FlutterArgs.string(args, "tileUrl")?.trimmingCharacters(in: .whitespacesAndNewlines)
      ?? OlaMapDefaults.tileURL
    let projectId = FlutterArgs.string(args, "projectId")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let userId = FlutterArgs.string(args, "userId")

    let myLocationEnabled = FlutterArgs.bool(args, "myLocationEnabled", true)
    let showMyLocationButton = FlutterArgs.bool(args, "showMyLocationButton", true)
    let rotateGesturesEnabled = FlutterArgs.bool(args, "rotateGesturesEnabled", true)
    let initialLatitude = FlutterArgs.double(args, "initialLatitude")
    let initialLongitude = FlutterArgs.double(args, "initialLongitude")
    lastZoom = FlutterArgs.double(args, "initialZoom") ?? 15

    guard let url = URL(string: tileURL) else {
      notifyMapError("Invalid Ola Maps tile URL")
      return
    }

    let service = OlaMapService(
      auth: .apiKey(key: apiKey),
      tileURL: url,
      projectId: projectId,
      userId: userId
    )
    olaMap = service
    service.delegate = self
    service.setDebugLogs(true)
    service.setMaxZoomLevel(20)

    let coordinate: OlaCoordinate
    if let latitude = initialLatitude, let longitude = initialLongitude {
      coordinate = OlaCoordinate(latitude: latitude, longitude: longitude)
    } else {
      coordinate = OlaCoordinate(latitude: 18.5204, longitude: 73.8567)
    }
    lastCoordinate = coordinate
    service.loadMap(onView: container, coordinate: coordinate, showCurrentLocationIcon: myLocationEnabled)
    service.setCamera(at: coordinate, zoomLevel: lastZoom)

    service.setRotatingGesture(rotateGesturesEnabled)
    showsUserLocation = myLocationEnabled
    service.setUserLocationOnMap(myLocationEnabled)
    if myLocationEnabled {
      locationManager.requestWhenInUseAuthorization()
      locationManager.startUpdatingLocation()
      service.setCurrentLocationMarkerColor(.systemBlue)
      if showMyLocationButton {
        service.addCurrentLocationButton(container)
        locationButtonAdded = true
      }
    }

    // iOS has no explicit map-ready callback; first idle / short delay unblocks Flutter.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.notifyMapReady()
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "waitUntilMapReady":
      waitUntilMapReady(result: result)
    case "addMarker":
      result(addMarker(args))
    case "removeMarker":
      if let markerId = FlutterArgs.string(args, "markerId") {
        removeMarker(markerId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing markerId", details: nil))
      }
    case "updateMarker":
      updateMarker(args)
      result(nil)
    case "showInfoWindow":
      if let markerId = FlutterArgs.string(args, "markerId") {
        showInfoWindow(markerId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing markerId", details: nil))
      }
    case "hideInfoWindow":
      if let markerId = FlutterArgs.string(args, "markerId") {
        hideInfoWindow(markerId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing markerId", details: nil))
      }
    case "updateInfoWindow":
      if let markerId = FlutterArgs.string(args, "markerId"),
         let text = FlutterArgs.string(args, "text") {
        updateInfoWindow(markerId, text: text)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing markerId or text", details: nil))
      }
    case "addPolyline":
      result(addPolyline(args))
    case "removePolyline":
      if let polylineId = FlutterArgs.string(args, "polylineId") {
        removePolyline(polylineId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing polylineId", details: nil))
      }
    case "updatePolyline":
      updatePolyline(args)
      result(nil)
    case "addCircle":
      result(addCircle(args))
    case "removeCircle":
      if let circleId = FlutterArgs.string(args, "circleId") {
        removeCircle(circleId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing circleId", details: nil))
      }
    case "updateCircle":
      updateCircle(args)
      result(nil)
    case "addPolygon":
      result(addPolygon(args))
    case "removePolygon":
      if let polygonId = FlutterArgs.string(args, "polygonId") {
        removePolygon(polygonId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing polygonId", details: nil))
      }
    case "updatePolygon":
      updatePolygon(args)
      result(nil)
    case "addBezierCurve":
      result(addBezierCurve(args))
    case "removeBezierCurve":
      if let curveId = FlutterArgs.string(args, "curveId") {
        removeBezierCurve(curveId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing curveId", details: nil))
      }
    case "updateBezierCurve":
      updateBezierCurve(args)
      result(nil)
    case "zoomToLocation":
      if let latitude = FlutterArgs.double(args, "latitude"),
         let longitude = FlutterArgs.double(args, "longitude"),
         let zoomLevel = FlutterArgs.double(args, "zoomLevel") {
        zoomToLocation(latitude: latitude, longitude: longitude, zoomLevel: zoomLevel)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
      }
    case "zoomIn":
      zoomBy(1)
      result(nil)
    case "zoomOut":
      zoomBy(-1)
      result(nil)
    case "moveCamera":
      if let latitude = FlutterArgs.double(args, "latitude"),
         let longitude = FlutterArgs.double(args, "longitude") {
        let zoomLevel = FlutterArgs.double(args, "zoomLevel") ?? lastZoom
        moveCamera(latitude: latitude, longitude: longitude, zoomLevel: zoomLevel)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
      }
    case "getCurrentLocation":
      result(getCurrentLocation())
    case "getCameraPosition":
      result(getCameraPosition())
    case "showCurrentLocation":
      showCurrentLocation()
      result(nil)
    case "hideCurrentLocation":
      hideCurrentLocation()
      result(nil)
    case "addClusteredMarkers":
      result(addClusteredMarkers(args))
    case "updateClusteredMarkers":
      updateClusteredMarkers(args)
      result(nil)
    case "removeClusteredMarkers":
      if let clusterId = FlutterArgs.string(args, "clusterId") {
        removeClusteredMarkers(clusterId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing clusterId", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func waitUntilMapReady(result: @escaping FlutterResult) {
    if let mapError {
      result(FlutterError(code: "MAP_ERROR", message: mapError, details: nil))
      return
    }
    if isMapReady {
      result(nil)
      return
    }
    pendingReadyResult = result
  }

  private func notifyMapReady() {
    guard !isMapReady, mapError == nil else { return }
    isMapReady = true
    pendingReadyResult?(nil)
    pendingReadyResult = nil
    methodChannel.invokeMethod("onMapReady", arguments: nil)
  }

  private func notifyMapError(_ error: String) {
    mapError = error
    pendingReadyResult?(FlutterError(code: "MAP_ERROR", message: error, details: nil))
    pendingReadyResult = nil
    methodChannel.invokeMethod("onMapError", arguments: error)
  }

  private func emitCameraIdle() {
    guard let position = getCameraPosition() else { return }
    cameraEvents?(position)
  }

  // MARK: - Markers

  @discardableResult
  private func addMarker(_ args: [String: Any]?) -> String? {
    guard let olaMap,
          let markerId = FlutterArgs.string(args, "markerId"),
          let latitude = FlutterArgs.double(args, "latitude"),
          let longitude = FlutterArgs.double(args, "longitude") else { return nil }
    let record = MarkerRecord(
      id: markerId,
      latitude: latitude,
      longitude: longitude,
      rotation: FlutterArgs.double(args, "iconRotation") ?? 0,
      snippet: FlutterArgs.string(args, "snippet"),
      subSnippet: FlutterArgs.string(args, "subSnippet"),
      iconPath: FlutterArgs.string(args, "iconPath"),
      iconSize: FlutterArgs.double(args, "iconSize"),
      showingInfo: false
    )
    placeMarker(record, on: olaMap)
    markers[markerId] = record
    return markerId
  }

  private func placeMarker(_ record: MarkerRecord, on olaMap: OlaMapService) {
    let coordinate = OlaCoordinate(latitude: record.latitude, longitude: record.longitude)
    if record.showingInfo, let text = record.infoText {
      let info = InfoAnnotationView(
        identifier: record.id,
        model: InfoAnnotationDecorator(),
        text: text,
        isActive: true
      )
      olaMap.setAnnotationMarker(at: coordinate, annotationView: info, identifier: record.id)
      return
    }

    let image = markerImage(path: record.iconPath)
    let annotation = CustomAnnotationView(identifier: record.id, image: image)
    let size = record.iconSize ?? 40
    annotation.bounds = CGRect(x: 0, y: 0, width: size, height: size)
    annotation.setRotate(record.rotation)
    annotation.didSelectOnAnnotation = { [weak self] identifier in
      self?.methodChannel.invokeMethod("onMarkerClick", arguments: ["markerId": identifier])
    }
    olaMap.setAnnotationMarker(at: coordinate, annotationView: annotation, identifier: record.id)
  }

  private func removeMarker(_ markerId: String) {
    olaMap?.removeAnnotation(by: markerId)
    markers.removeValue(forKey: markerId)
  }

  private func updateMarker(_ args: [String: Any]?) {
    guard let markerId = FlutterArgs.string(args, "markerId"), var record = markers[markerId] else { return }
    if let latitude = FlutterArgs.double(args, "latitude") { record.latitude = latitude }
    if let longitude = FlutterArgs.double(args, "longitude") { record.longitude = longitude }
    if let rotation = FlutterArgs.double(args, "iconRotation") { record.rotation = rotation }
    if let snippet = FlutterArgs.string(args, "snippet") { record.snippet = snippet }
    if let subSnippet = FlutterArgs.string(args, "subSnippet") { record.subSnippet = subSnippet }
    if let iconPath = FlutterArgs.string(args, "iconPath") { record.iconPath = iconPath }
    if let iconSize = FlutterArgs.double(args, "iconSize") { record.iconSize = iconSize }
    markers[markerId] = record
    guard let olaMap else { return }
    olaMap.removeAnnotation(by: markerId)
    placeMarker(record, on: olaMap)
  }

  private func showInfoWindow(_ markerId: String) {
    guard var record = markers[markerId], let olaMap, record.infoText != nil else { return }
    record.showingInfo = true
    markers[markerId] = record
    olaMap.removeAnnotation(by: markerId)
    placeMarker(record, on: olaMap)
  }

  private func hideInfoWindow(_ markerId: String) {
    guard var record = markers[markerId], let olaMap else { return }
    record.showingInfo = false
    markers[markerId] = record
    olaMap.removeAnnotation(by: markerId)
    placeMarker(record, on: olaMap)
  }

  private func updateInfoWindow(_ markerId: String, text: String) {
    guard var record = markers[markerId] else { return }
    record.snippet = text
    record.showingInfo = true
    markers[markerId] = record
    showInfoWindow(markerId)
  }

  private func markerImage(path: String?) -> UIImage {
    if let path, let image = loadAssetImage(path) {
      return image
    }
    return OlaMapStyle.defaultPin()
  }

  private func loadAssetImage(_ assetName: String) -> UIImage? {
    let key = registrar.lookupKey(forAsset: assetName)
    if let path = Bundle.main.path(forResource: key, ofType: nil) {
      return UIImage(contentsOfFile: path)
    }
    return UIImage(named: assetName)
  }

  // MARK: - Overlays

  @discardableResult
  private func addPolyline(_ args: [String: Any]?) -> String? {
    guard let olaMap,
          let polylineId = FlutterArgs.string(args, "polylineId") else { return nil }
    let points = FlutterArgs.coordinates(args?["points"])
    guard !points.isEmpty else { return nil }
    let color = OlaMapStyle.color(FlutterArgs.string(args, "color")) ?? .darkGray
    let width = FlutterArgs.double(args, "width").map { CGFloat($0) }
    let type: PolylineType
    switch FlutterArgs.string(args, "lineType")?.uppercased() {
    case "LINE_DOTTED", "DOTTED", "DASHED", "LINE_DASHED":
      type = .dashed
    default:
      type = .solid
    }
    olaMap.showPolyline(identifier: polylineId, type, points, color, width)
    polylines[polylineId] = OverlayRecord(id: polylineId, points: points, color: FlutterArgs.string(args, "color"), extra: FlutterArgs.double(args, "width"))
    return polylineId
  }

  private func removePolyline(_ polylineId: String) {
    olaMap?.deletePolyline(polylineId)
    polylines.removeValue(forKey: polylineId)
  }

  private func updatePolyline(_ args: [String: Any]?) {
    guard let polylineId = FlutterArgs.string(args, "polylineId"),
          var record = polylines[polylineId] else { return }
    if let points = args?["points"] { record.points = FlutterArgs.coordinates(points) }
    if let color = FlutterArgs.string(args, "color") { record.color = color }
    if let width = FlutterArgs.double(args, "width") { record.extra = width }
    polylines[polylineId] = record
    removePolyline(polylineId)
    _ = addPolyline([
      "polylineId": polylineId,
      "points": record.points.map { ["latitude": $0.getLatitude, "longitude": $0.getLongitude] },
      "color": record.color as Any,
      "width": record.extra as Any,
      "lineType": FlutterArgs.string(args, "lineType") as Any,
    ])
  }

  @discardableResult
  private func addPolygon(_ args: [String: Any]?) -> String? {
    guard let olaMap,
          let polygonId = FlutterArgs.string(args, "polygonId") else { return nil }
    let points = FlutterArgs.coordinates(args?["points"])
    guard !points.isEmpty else { return nil }
    let fill = OlaMapStyle.color(FlutterArgs.string(args, "color"), alpha: 0.25) ?? UIColor.systemGreen.withAlphaComponent(0.25)
    let stroke = OlaMapStyle.color(FlutterArgs.string(args, "borderColor")) ?? .black
    let width = CGFloat(FlutterArgs.double(args, "borderWidth") ?? 2)
    olaMap.drawPolygon(identifier: polygonId, points, zoneColor: fill, strokeColor: stroke, storkeWidth: width)
    polygons[polygonId] = OverlayRecord(id: polygonId, points: points, color: FlutterArgs.string(args, "color"), extra: FlutterArgs.double(args, "borderWidth"), extraColor: FlutterArgs.string(args, "borderColor"))
    return polygonId
  }

  private func removePolygon(_ polygonId: String) {
    olaMap?.deletePolygon(polygonId)
    polygons.removeValue(forKey: polygonId)
  }

  private func updatePolygon(_ args: [String: Any]?) {
    guard let polygonId = FlutterArgs.string(args, "polygonId"),
          var record = polygons[polygonId] else { return }
    if let points = args?["points"] { record.points = FlutterArgs.coordinates(points) }
    if let color = FlutterArgs.string(args, "color") { record.color = color }
    if let border = FlutterArgs.string(args, "borderColor") { record.extraColor = border }
    if let width = FlutterArgs.double(args, "borderWidth") { record.extra = width }
    polygons[polygonId] = record
    removePolygon(polygonId)
    _ = addPolygon([
      "polygonId": polygonId,
      "points": record.points.map { ["latitude": $0.getLatitude, "longitude": $0.getLongitude] },
      "color": record.color as Any,
      "borderColor": record.extraColor as Any,
      "borderWidth": record.extra as Any,
    ])
  }

  @discardableResult
  private func addCircle(_ args: [String: Any]?) -> String? {
    guard let olaMap,
          let circleId = FlutterArgs.string(args, "circleId"),
          let latitude = FlutterArgs.double(args, "latitude"),
          let longitude = FlutterArgs.double(args, "longitude"),
          let radius = FlutterArgs.double(args, "radius") else { return nil }
    let coordinate = OlaCoordinate(latitude: latitude, longitude: longitude)
    let opacity = FlutterArgs.double(args, "opacity") ?? 0.3
    let fill = OlaMapStyle.color(FlutterArgs.string(args, "color"), alpha: opacity) ?? UIColor.systemBlue.withAlphaComponent(CGFloat(opacity))
    let stroke = OlaMapStyle.color(FlutterArgs.string(args, "borderColor")) ?? .black
    let width = CGFloat(FlutterArgs.double(args, "borderWidth") ?? 2)
    olaMap.drawCircle(
      id: circleId,
      centerCoordinate: coordinate,
      radius: radius,
      strokeColor: stroke,
      zoneColor: fill,
      strokeWidth: width
    )
    circles[circleId] = OverlayRecord(
      id: circleId,
      points: [coordinate],
      color: FlutterArgs.string(args, "color"),
      extra: radius,
      extraColor: FlutterArgs.string(args, "borderColor")
    )
    return circleId
  }

  private func removeCircle(_ circleId: String) {
    olaMap?.deleteCircle(circleId)
    circles.removeValue(forKey: circleId)
  }

  private func updateCircle(_ args: [String: Any]?) {
    guard let circleId = FlutterArgs.string(args, "circleId"),
          var record = circles[circleId],
          let current = record.points.first else { return }
    let latitude = FlutterArgs.double(args, "latitude") ?? current.getLatitude
    let longitude = FlutterArgs.double(args, "longitude") ?? current.getLongitude
    if let color = FlutterArgs.string(args, "color") { record.color = color }
    if let radius = FlutterArgs.double(args, "radius") { record.extra = radius }
    if let border = FlutterArgs.string(args, "borderColor") { record.extraColor = border }
    record.points = [OlaCoordinate(latitude: latitude, longitude: longitude)]
    circles[circleId] = record
    removeCircle(circleId)
    _ = addCircle([
      "circleId": circleId,
      "latitude": latitude,
      "longitude": longitude,
      "radius": record.extra ?? 30,
      "color": record.color as Any,
      "borderColor": record.extraColor as Any,
      "borderWidth": FlutterArgs.double(args, "borderWidth") as Any,
      "opacity": FlutterArgs.double(args, "opacity") as Any,
    ])
  }

  @discardableResult
  private func addBezierCurve(_ args: [String: Any]?) -> String? {
    guard let startLatitude = FlutterArgs.double(args, "startLatitude"),
          let startLongitude = FlutterArgs.double(args, "startLongitude"),
          let endLatitude = FlutterArgs.double(args, "endLatitude"),
          let endLongitude = FlutterArgs.double(args, "endLongitude"),
          let curveId = FlutterArgs.string(args, "curveId") else { return nil }
    let points = OlaMapStyle.bezierPoints(
      start: OlaCoordinate(latitude: startLatitude, longitude: startLongitude),
      end: OlaCoordinate(latitude: endLatitude, longitude: endLongitude)
    )
    _ = addPolyline([
      "polylineId": curveId,
      "points": points.map { ["latitude": $0.getLatitude, "longitude": $0.getLongitude] },
      "color": FlutterArgs.string(args, "color") as Any,
      "lineType": FlutterArgs.string(args, "lineType") as Any,
      "width": FlutterArgs.double(args, "width") as Any,
    ])
    bezierCurves[curveId] = OverlayRecord(id: curveId, points: points, color: FlutterArgs.string(args, "color"))
    return curveId
  }

  private func removeBezierCurve(_ curveId: String) {
    removePolyline(curveId)
    bezierCurves.removeValue(forKey: curveId)
  }

  private func updateBezierCurve(_ args: [String: Any]?) {
    guard let curveId = FlutterArgs.string(args, "curveId") else { return }
    removeBezierCurve(curveId)
    _ = addBezierCurve(args)
  }

  private func zoomToLocation(latitude: Double, longitude: Double, zoomLevel: Double) {
    lastZoom = zoomLevel
    let coordinate = OlaCoordinate(latitude: latitude, longitude: longitude)
    lastCoordinate = coordinate
    olaMap?.setCamera(at: coordinate, zoomLevel: zoomLevel)
  }

  private func zoomBy(_ delta: Double) {
    let currentZoom = olaMap?.getZoomLevel() ?? lastZoom
    let zoom = max(1, min(20, currentZoom + delta))
    if let lastCoordinate {
      zoomToLocation(latitude: lastCoordinate.getLatitude, longitude: lastCoordinate.getLongitude, zoomLevel: zoom)
    } else if let center = olaMap?.centerCoordinateOfMap {
      zoomToLocation(latitude: center.latitude, longitude: center.longitude, zoomLevel: zoom)
    } else {
      olaMap?.setZoomLevel(zoom)
      lastZoom = zoom
    }
  }

  private func moveCamera(latitude: Double, longitude: Double, zoomLevel: Double) {
    zoomToLocation(latitude: latitude, longitude: longitude, zoomLevel: zoomLevel)
  }

  private func getCurrentLocation() -> [String: Double]? {
    if let user = olaMap?.userLocation {
      return [
        "latitude": user.coordinate.latitude,
        "longitude": user.coordinate.longitude,
      ]
    }
    if let coordinate = olaMap?.getUserCurrentCoordinate() {
      return [
        "latitude": coordinate.getLatitude,
        "longitude": coordinate.getLongitude,
      ]
    }
    if let lastDeviceLocation {
      return [
        "latitude": lastDeviceLocation.coordinate.latitude,
        "longitude": lastDeviceLocation.coordinate.longitude,
      ]
    }
    return nil
  }

  private func getCameraPosition() -> [String: Double]? {
    if let center = olaMap?.centerCoordinateOfMap {
      lastCoordinate = OlaCoordinate(center)
      lastZoom = olaMap?.getZoomLevel() ?? lastZoom
      return [
        "latitude": center.latitude,
        "longitude": center.longitude,
        "zoom": lastZoom,
        "bearing": 0,
        "tilt": 0,
      ]
    }
    guard let coordinate = lastCoordinate else { return nil }
    return [
      "latitude": coordinate.getLatitude,
      "longitude": coordinate.getLongitude,
      "zoom": lastZoom,
      "bearing": 0,
      "tilt": 0,
    ]
  }

  private func showCurrentLocation() {
    showsUserLocation = true
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    olaMap?.setUserLocationOnMap(true)
    olaMap?.setCurrentLocationMarkerColor(.systemBlue)
    if !locationButtonAdded {
      olaMap?.addCurrentLocationButton(container)
      locationButtonAdded = true
    }
    olaMap?.recenterMapToUserLocation(zoomLevel: lastZoom)
  }

  private func hideCurrentLocation() {
    showsUserLocation = false
    locationManager.stopUpdatingLocation()
    olaMap?.setUserLocationOnMap(false)
  }

  @discardableResult
  private func addClusteredMarkers(_ args: [String: Any]?) -> String? {
    guard let olaMap, let geoJson = FlutterArgs.string(args, "geoJson") else { return nil }
    let points = FlutterArgs.geoJsonPoints(geoJson)
    let image = markerImage(path: FlutterArgs.string(args, "iconPath"))
    let markers = points.enumerated().map { index, point in
      ClusterMarker(markerId: "c_\(index)", image: image, coordinate: point)
    }
    let clusterColor = OlaMapStyle.color(FlutterArgs.string(args, "defaultClusterColor")) ?? .systemGreen
    let textColor = OlaMapStyle.color(FlutterArgs.string(args, "textColor")) ?? .white
    let decorator = ClusterViewDecorator(
      backgroundColor: clusterColor,
      opacity: 1,
      radius: FlutterArgs.double(args, "clusterRadius") ?? 50,
      cluserViewRadius: 24,
      borderWidth: 2,
      borderColor: .white,
      fontSize: FlutterArgs.double(args, "textSize") ?? 12,
      fontColor: textColor
    )
    olaMap.drawClusterMarker(markers, clusterDecorator: decorator)
    let clusterId = "cluster_\(Int(Date().timeIntervalSince1970 * 1000))"
    clusters[clusterId] = markers.map(\.markerId)
    return clusterId
  }

  private func updateClusteredMarkers(_ args: [String: Any]?) {
    guard let clusterId = FlutterArgs.string(args, "clusterId") else { return }
    removeClusteredMarkers(clusterId)
    _ = addClusteredMarkers(args)
  }

  private func removeClusteredMarkers(_ clusterId: String) {
    clusters.removeValue(forKey: clusterId)
    olaMap?.clearCluster()
  }

  // MARK: - OlaMapServiceDelegate

  public func didTapOnMap(_ coordinate: OlaCoordinate) {
    methodChannel.invokeMethod("onMapClick", arguments: [
      "latitude": coordinate.getLatitude,
      "longitude": coordinate.getLongitude,
    ])
  }

  public func didLongTapOnMap(_ coordinate: OlaCoordinate) {
    methodChannel.invokeMethod("onMapLongClick", arguments: [
      "latitude": coordinate.getLatitude,
      "longitude": coordinate.getLongitude,
    ])
  }

  public func mapSuccessfullyLoaded() {
    notifyMapReady()
  }

  public func didSelectAnnotationView(_ annotationId: String) {
    methodChannel.invokeMethod("onMarkerClick", arguments: ["markerId": annotationId])
  }

  public func mapViewDidBecomeIdle() {
    notifyMapReady()
    emitCameraIdle()
  }

  public func mapViewDidChange(gesture: OlaMapGesture) {
    if let center = olaMap?.centerCoordinateOfMap {
      lastCoordinate = OlaCoordinate(center)
    }
  }

  public func didChangeCamera() {
    if let center = olaMap?.centerCoordinateOfMap {
      lastCoordinate = OlaCoordinate(center)
    }
  }

  public func regionIsChanging(_ gesture: OlaMapGesture) {
    if let center = olaMap?.centerCoordinateOfMap {
      lastCoordinate = OlaCoordinate(center)
    }
  }

  public func mapFailedToLoad(_ error: Error) {
    notifyMapError(error.localizedDescription)
  }

  public func didChangeLocationManagerAuthorization(_ state: CLAuthorizationStatus) {
    if state == .authorizedWhenInUse || state == .authorizedAlways {
      if showsUserLocation {
        olaMap?.recenterMapToUserLocation(zoomLevel: lastZoom)
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    lastDeviceLocation = locations.last
  }
}

private final class CameraStreamHandler: NSObject, FlutterStreamHandler {
  private let onListen: (FlutterEventSink?) -> Void

  init(onListen: @escaping (FlutterEventSink?) -> Void) {
    self.onListen = onListen
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onListen(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onListen(nil)
    return nil
  }
}

private struct MarkerRecord {
  var id: String
  var latitude: Double
  var longitude: Double
  var rotation: Double
  var snippet: String?
  var subSnippet: String?
  var iconPath: String?
  var iconSize: Double?
  var showingInfo: Bool

  var infoText: String? {
    let parts = [snippet, subSnippet].compactMap { $0 }.filter { !$0.isEmpty }
    return parts.isEmpty ? nil : parts.joined(separator: "\n")
  }
}

private struct OverlayRecord {
  var id: String
  var points: [OlaCoordinate]
  var color: String?
  var extra: Double?
  var extraColor: String?
}

enum OlaMapDefaults {
  static let tileURL = "https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json"
}

enum FlutterArgs {
  static func string(_ map: [String: Any]?, _ key: String) -> String? {
    map?[key] as? String
  }

  static func double(_ map: [String: Any]?, _ key: String) -> Double? {
    if let number = map?[key] as? NSNumber { return number.doubleValue }
    if let value = map?[key] as? Double { return value }
    return nil
  }

  static func bool(_ map: [String: Any]?, _ key: String, _ defaultValue: Bool) -> Bool {
    (map?[key] as? Bool) ?? defaultValue
  }

  static func coordinates(_ value: Any?) -> [OlaCoordinate] {
    guard let list = value as? [[String: Any]] else { return [] }
    return list.compactMap { item in
      guard let latitude = (item["latitude"] as? NSNumber)?.doubleValue ?? item["latitude"] as? Double,
            let longitude = (item["longitude"] as? NSNumber)?.doubleValue ?? item["longitude"] as? Double else {
        return nil
      }
      return OlaCoordinate(latitude: latitude, longitude: longitude)
    }
  }

  static func geoJsonPoints(_ geoJson: String) -> [OlaCoordinate] {
    guard let data = geoJson.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let features = json["features"] as? [[String: Any]] else { return [] }
    return features.compactMap { feature in
      guard let geometry = feature["geometry"] as? [String: Any],
            let coords = geometry["coordinates"] as? [Any],
            coords.count >= 2,
            let longitude = (coords[0] as? NSNumber)?.doubleValue ?? coords[0] as? Double,
            let latitude = (coords[1] as? NSNumber)?.doubleValue ?? coords[1] as? Double else {
        return nil
      }
      return OlaCoordinate(latitude: latitude, longitude: longitude)
    }
  }
}

enum OlaMapStyle {
  static func color(_ hex: String?, alpha: Double = 1) -> UIColor? {
    guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
      return nil
    }
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6 || value.count == 8, let intVal = UInt64(value, radix: 16) else {
      return nil
    }
    let hasAlpha = value.count == 8
    let a = hasAlpha ? CGFloat((intVal & 0xFF000000) >> 24) / 255 : CGFloat(alpha)
    let r = CGFloat((intVal & 0xFF0000) >> 16) / 255
    let g = CGFloat((intVal & 0x00FF00) >> 8) / 255
    let b = CGFloat(intVal & 0x0000FF) / 255
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  static func defaultPin() -> UIImage {
    let size = CGSize(width: 36, height: 44)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      let pin = UIBezierPath()
      pin.addArc(
        withCenter: CGPoint(x: 18, y: 14),
        radius: 12,
        startAngle: .pi,
        endAngle: 0,
        clockwise: true
      )
      pin.addLine(to: CGPoint(x: 18, y: 42))
      pin.close()
      UIColor.systemRed.setFill()
      pin.fill()
      UIColor.white.setFill()
      UIBezierPath(ovalIn: CGRect(x: 12, y: 8, width: 12, height: 12)).fill()
    }
  }

  static func bezierPoints(start: OlaCoordinate, end: OlaCoordinate) -> [OlaCoordinate] {
    let coords = MapUtility.createArcPolyline(
      startPoint: start.getCLCoordinate2D(),
      toEnd: end.getCLCoordinate2D(),
      withAngle: 45
    )
    return coords.map { OlaCoordinate($0) }
  }
}
