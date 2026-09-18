## 0.3.0

* Added Flutter **web** `OlaMapView` via [Ola Maps Web SDK v2](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup) (`olamaps-web-sdk`), including markers, popups, events/controls, geolocation, 3D tiles, and GeoJSON overlays.
* Added multilingual `language` support (12 ISO 639-1 codes) across Places, Routing, Geocoding, Static Maps, and iOS Dynamic Maps.
* Completed Flutter Android Map SDK integration against Ola Maps SDK 1.8.4.
* Added iOS `OlaMapView` via `OlaMapService` (api key, tile URL, project id), location Info.plist keys, and CocoaPods `OlaMapCore`.
* Added HTTP clients for Roads, Places (advanced details/nearby, address validation, photos), Geofencing, Elevation, Tiles, Street View, distance matrix, route optimizer, and fleet planner.
* Implemented native marker clustering, map-ready waiting, zoom in/out, show info window, map/marker tap events, and overlay borders.
* `OlaMapView` now waits until the native map is ready before `onControllerReady`.
* Example app uses the official AAR + MapLibre dependencies (`minSdk 24`) and demos all overlay APIs.

## 0.2.0

* Vendored [`ola_maps_flutter` 0.2.0](https://pub.dev/packages/ola_maps_flutter) into this repo as package `ola_maps`.
* Kept Places / Geocoder helpers (`Olamaps`, autocomplete widgets).
* Added `getCameraPosition` and `onCameraIdle` for center-pin location pickers.
* Fixed `OlaMapController` to be per-map-instance (not a global singleton).
