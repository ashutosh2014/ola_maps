# ola_maps

Flutter plugin for [Ola Maps](https://maps.olakrutrim.com/) — Android, iOS, and Web map views plus Places / Geocoder helpers.

Wraps [Ola Maps Android SDK 1.8.4](https://github.com/ola-maps/android-maps-sdk), [Ola Maps iOS SDK (`OlaMapCore` / `OlaMapService`)](https://github.com/ola-maps/ios-map-sdk), and [Ola Maps Web SDK v2 (`olamaps-web-sdk`)](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup) as Flutter `PlatformView`s / `HtmlElementView`. Existing Places API helpers from this repo stay under `lib/ola_maps_api.dart`.

## Features

- Interactive map (`OlaMapView`) on **Android**, **iOS**, and **Web**
- Markers, info windows, polylines, circles, polygons, bezier curves, clustering
- Camera: `zoomToLocation`, `moveCamera`, `zoomIn` / `zoomOut`, `getCamera`, `onCameraIdle`
- Map events: tap, long-press, marker tap, map error
- Location: show / hide current location
- Routing helper (`OlaRoutingService`) plus distance matrix, route optimizer, fleet planner
- HTTP APIs: Places, Geocode, Roads, Geofencing, Elevation, Tiles, Street View (`Olamaps.instance`)
- Multilingual names, addresses, and turn-by-turn instructions in 12 languages (`language` / [OlaMapsLanguage])

iOS maps use `OlaMapService` (api key, tile URL, project id). Native iOS overlay APIs differ slightly from Android (annotations vs markers; bezier/clustering are approximated). Web maps use the [Ola Maps Web SDK](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup) (MapLibre) with the same `OlaMapController` overlay methods.

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
  tileUrl: kOlaMapsDefaultTileUrl,
  language: OlaMapsLanguage.hi, // Dynamic Maps: default-light-standard-hi
  projectId: 'YOUR_PROJECT_ID', // iOS OlaMapService; from the Ola Maps dashboard
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

### REST APIs (`Olamaps.instance`)

Initialize once with your dashboard API key, then call Places, Geocode, Roads, Geofencing, Elevation, Tiles, Street View, and Routing.

```dart
Olamaps.instance.initialize(
  'YOUR_OLA_MAPS_API_KEY',
  language: OlaMapsLanguage.hi, // or 'hi'
);

final maps = Olamaps.instance;

final suggestions = await maps.places.getAutocompleteSuggestions(
  input: 'रेस्टोरेंट',
  language: OlaMapsLanguage.hi,
);
final details = await maps.places.getPlaceDetails(
  placeId: suggestions.first.placeId,
  language: OlaMapsLanguage.ta,
);
final advanced = await maps.places.getAdvancedPlaceDetails(placeId: details.placeId);
final nearby = await maps.places.getNearBySearchPlaces(
  location: Location(lat: 12.9315, lng: 77.6164),
  types: ['cafe'],
);
await maps.places.validateAddress('7, Lok Kalyan Marg, New Delhi');
await maps.places.getPhoto('photo_reference');

final addresses = await maps.geoencoder.fetchAddresses(
  Location(lat: 12.9313, lng: 77.6165),
  language: OlaMapsLanguage.bn,
);
final geocoded = await maps.geoencoder.fetchLocation('Mumbai');

await maps.roads.snapToRoad(points: [
  Location(lat: 12.9993, lng: 77.6732),
  Location(lat: 12.9921, lng: 77.6590),
]);
await maps.roads.nearestRoads(
  points: [Location(lat: 12.9993, lng: 77.6732)],
  mode: 'DRIVING',
);
await maps.roads.speedLimits(points: [
  Location(lat: 13.0630, lng: 77.5931),
]);

await maps.elevation.getElevation(Location(lat: 12.93126, lng: 77.61638));
await maps.geofence.list(projectId: 'YOUR_PROJECT_ID', page: 1, size: 10);

final png = await maps.tiles.staticMapByCenter(
  longitude: 77.61,
  latitude: 12.93,
  zoom: 15,
  language: OlaMapsLanguage.ml,
);
await maps.streetView.nearestImageId(latitude: 12.9345, longitude: 77.6136);

await maps.routing.getDirectionsRaw(
  origin: Location(lat: 12.9716, lng: 77.5946),
  destination: Location(lat: 13.0827, lng: 80.2707),
  language: OlaMapsLanguage.kn,
);
await maps.routing.getDistanceMatrix(
  origins: [Location(lat: 12.93, lng: 77.61)],
  destinations: [Location(lat: 12.97, lng: 77.59)],
);
```

### Multilingual support

Pass `language` as an ISO 639-1 code or [OlaMapsLanguage] (`en`, `hi`, `kn`, `te`, `ta`, `ml`, `sa`, `bn`, `gu`, `mr`, `or`, `ur`). Omitted values default to English (`en`).

| API | Where `language` is sent |
| --- | --- |
| Places (Autocomplete, Details, Nearby, Text Search) | GET query |
| Routing (Directions, Directions Basic, Distance Matrix) | GET/POST query |
| Route Optimizer / Fleet Planner | POST body |
| Reverse / forward Geocoding | GET query |
| Static Maps | Localized style id (`default-light-standard-ml`) plus query |
| Dynamic Maps (`OlaMapView` / `tiles.styleUrl`) | Style URL, e.g. `.../styles/default-light-standard-ml/style.json` |

Per-call `language` overrides `Olamaps.instance.initialize(..., language:)`. Some landmarks or technical terms may still appear in English.

```dart
await maps.places.getAutocompleteSuggestions(
  input: 'रेस्टोरेंट',
  language: 'hi',
);
print(maps.tiles.styleUrl(language: 'ml'));
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

## iOS setup (required once per app)

Minimum iOS **15.0** (Flutter engine) / Ola Maps SDK **13.0**, Xcode 12+. The map is `OlaMapService` from [OlaMapCore](https://github.com/ola-maps/ios-map-sdk) (same initializer as the Navigation SDK docs: api key, tile URL, project id).

1. In the app `ios/Podfile`:

```ruby
platform :ios, '15.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Not published on CocoaPods trunk — pin the git source.
  pod 'OlaMapCore', :git => 'https://github.com/ola-maps/ios-map-sdk.git', :tag => '1.0.8'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

Then `cd ios && pod install`.

Alternatively, download the xcframeworks from the SDK release, add them to the Xcode project, and **Embed & Sign** every framework under General → Frameworks, Libraries, and Embedded Content.

2. Location keys in `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App wants to access your location</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>App wants to access your location</string>
```

3. Pass `projectId` (dashboard project / workspace id) and optionally `tileUrl` / `userId` / `language` into `OlaMapView`. Default English tiles:

`https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json`

Malayalam (and other non-English) labels use `default-light-standard-{code}`:

`https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard-ml/style.json`

Turn-by-turn navigation (`OlaMapNavigationService`) is a separate [Navigation SDK](https://github.com/ola-maps/ios-navigation-sdk) and is not wrapped by `OlaMapView`.

## Web setup

Uses [Ola Maps Web SDK v2](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup) (`olamaps-web-sdk` ≥ 1.2.0). The plugin loads the UMD bundle from UNPKG if it is not already on the page. You can also inject it yourself:

```html
<script src="https://www.unpkg.com/olamaps-web-sdk@1.4.0/dist/olamaps-web-sdk.umd.js"></script>
```

`OlaMapView` still takes `apiKey`, `tileUrl`, and `language`. Non-English styles append `-{code}` (for example Marathi):

`https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard-mr/style.json`

Optional 3D mode:

```dart
OlaMapView(
  apiKey: 'YOUR_OLA_MAPS_API_KEY',
  mode3d: true,
  threeDTileset: kOlaMapsDefaultThreeDTileset,
  projectId: 'YOUR_PROJECT_ID',
)
```

Markers, popups, click / idle / error events, compass / zoom controls, and geolocation use the Web SDK (`addMarker`, `addPopup`, `NavigationControl`, `addGeolocateControls`). Polylines, polygons, circles, bezier curves, and clustering are GeoJSON layers on the MapLibre map returned by `olaMaps.init`.

## Example app

```bash
cd example
flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY --dart-define=OLA_MAPS_PROJECT_ID=YOUR_PROJECT_ID --dart-define=OLA_MAPS_LANGUAGE=hi
flutter run -d chrome --dart-define=OLA_MAPS_API_KEY=YOUR_KEY --dart-define=OLA_MAPS_LANGUAGE=mr
```

The example demos markers, polylines, circles, polygons, bezier curves, clustering, routing, and current location.

## Requirements

- Flutter SDK ≥ 3.22
- Android `minSdk` ≥ 24, Ola Maps Android SDK **1.8.4**
- iOS 15.0+, OlaMapCore **1.0.8** (`OlaMapService`)
- Web: `olamaps-web-sdk` **1.4.0** (loaded from CDN)

## License

MIT — see [LICENSE](LICENSE). Upstream map plugin: [imselmon/ola_maps_flutter](https://github.com/imselmon/ola_maps_flutter). Android SDK: [ola-maps/android-maps-sdk](https://github.com/ola-maps/android-maps-sdk). iOS SDK: [ola-maps/ios-map-sdk](https://github.com/ola-maps/ios-map-sdk). Web SDK: [ola-maps/olamaps-web-sdk](https://github.com/ola-maps/olamaps-web-sdk).
