## 0.3.0

* Completed Flutter Android Map SDK integration against Ola Maps SDK 1.8.4.
* Implemented native marker clustering, map-ready waiting, zoom in/out, show info window, map/marker tap events, and overlay borders.
* `OlaMapView` now waits until the native map is ready before `onControllerReady`.
* Example app uses the official AAR + MapLibre dependencies (`minSdk 24`) and demos all overlay APIs.

## 0.2.0

* Vendored [`ola_maps_flutter` 0.2.0](https://pub.dev/packages/ola_maps_flutter) into this repo as package `ola_maps`.
* Kept Places / Geocoder helpers (`Olamaps`, autocomplete widgets).
* Added `getCameraPosition` and `onCameraIdle` for center-pin location pickers.
* Fixed `OlaMapController` to be per-map-instance (not a global singleton).
