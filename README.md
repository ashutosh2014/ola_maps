# ola_maps

Flutter plugin for [Ola Maps](https://maps.olakrutrim.com/) — Android Map SDK view plus Places / Geocoder helpers.

Wraps [Ola Maps Android SDK 1.8.4](https://github.com/ola-maps/android-maps-sdk) as a Flutter `PlatformView`. Existing Places API helpers from this repo stay under `lib/ola_maps_api.dart`.

## Features

- Interactive map (`OlaMapView`) — Android only
- Markers, info windows, polylines, circles, polygons, bezier curves, clustering
- Camera: `zoomToLocation`, `moveCamera`, `zoomIn` / `zoomOut`, `getCamera`, `onCameraIdle`
- Map events: tap, long-press, marker tap, map error
- Location: show / hide current location
- Routing helper (`OlaRoutingService`)
- HTTP Places / reverse-geocode (`Olamaps.instance`)

## Use in an app

```yaml
dependencies:
  ola_maps:
    path: ../ola_maps   # or a git / pub dependency
```

```dart
import 'package:ola_maps/ola_maps.dart';

OlaMapView(
  apiKey: 'YOUR_OLA_MAPS_API_KEY',
  initialCameraPosition: const OlaLatLng(18.5214, 73.9317),
  initialZoom: 14,
  onControllerReady: (controller) {
    controller.onCameraIdle = (pos) {
      // map center after pan/zoom settles
    };
    controller.onMapClick = (pos) {
      controller.addMarker(position: pos, snippet: 'Dropped pin');
    };
    controller.zoomToLocation(const OlaLatLng(28.6139, 77.2090), 15);
  },
)
```

### Overlays

```dart
await controller.addMarker(
  position: const OlaLatLng(18.5214, 73.9317),
  snippet: 'Ola Campus',
);

await controller.addPolyline(
  points: const [
    OlaLatLng(12.9314, 77.6164),
    OlaLatLng(12.9317, 77.6143),
  ],
  color: '#FF0000',
  width: 5,
  lineType: OlaLineType.solid,
);

await controller.addCircle(
  center: const OlaLatLng(12.9314, 77.6164),
  radius: 100,
  color: '#0000FF',
  opacity: 0.3,
);

await controller.addPolygon(
  points: const [
    OlaLatLng(18.5689, 73.8808),
    OlaLatLng(18.5896, 73.8361),
    OlaLatLng(18.5906, 73.8361),
  ],
  color: '#00FF00',
);

await controller.addBezierCurve(
  startPoint: const OlaLatLng(12.9314, 77.6164),
  endPoint: const OlaLatLng(12.9317, 77.6143),
  color: '#FF00FF',
);

await controller.addClusteredMarkersFromPoints(
  points: const [
    OlaLatLng(18.5214, 73.9317),
    OlaLatLng(18.5220, 73.9325),
  ],
  clusterRadius: 50,
  defaultMarkerColor: '#FF0000',
  defaultClusterColor: '#00AA00',
);
```

## Android setup (required once per app)

AARs cannot be auto-bundled inside Flutter plugins, so the **app module** must depend on the SDK AAR (same as the official Android sample).

1. Copy `android/libs/OlaMapSdk-1.8.4.aar` from this package into your app’s `android/app/libs/`.

2. In `android/app/build.gradle` / `.kts`:

```kotlin
android {
    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    implementation(files("libs/OlaMapSdk-1.8.4.aar"))
    implementation("org.maplibre.gl:android-sdk:11.13.1")
    implementation("org.maplibre.gl:android-plugin-annotation-v9:3.0.2")
    implementation("org.maplibre.gl:android-plugin-markerview-v9:3.0.2")
}
```

3. Permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Example app

```bash
cd example
flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY
```

The example demos markers, polylines, circles, polygons, bezier curves, clustering, routing, and current location.

## Requirements

- Flutter SDK ≥ 3.3
- Android `minSdk` ≥ 24
- Ola Maps SDK **1.8.4**
- **iOS**: map view not supported yet (Places HTTP APIs still work)

## License

MIT — see [LICENSE](LICENSE). Upstream map plugin: [imselmon/ola_maps_flutter](https://github.com/imselmon/ola_maps_flutter). Android SDK: [ola-maps/android-maps-sdk](https://github.com/ola-maps/android-maps-sdk).
