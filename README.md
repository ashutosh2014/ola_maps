# ola_maps

Flutter plugin for [Ola Maps](https://maps.olakrutrim.com/) — Android and iOS map views plus Places / Geocoder helpers.

Wraps [Ola Maps Android SDK 1.8.4](https://github.com/ola-maps/android-maps-sdk) and [Ola Maps iOS SDK (`OlaMapCore` / `OlaMapService`)](https://github.com/ola-maps/ios-map-sdk) as Flutter `PlatformView`s. Existing Places API helpers from this repo stay under `lib/ola_maps_api.dart`.

## Features

- Interactive map (`OlaMapView`) on **Android** and **iOS**
- Markers, info windows, polylines, circles, polygons, bezier curves, clustering
- Camera: `zoomToLocation`, `moveCamera`, `zoomIn` / `zoomOut`, `getCamera`, `onCameraIdle`
- Map events: tap, long-press, marker tap, map error
- Location: show / hide current location
- Routing helper (`OlaRoutingService`) plus distance matrix, route optimizer, fleet planner
- HTTP APIs: Places, Geocode, Roads, Geofencing, Elevation, Tiles, Street View (`Olamaps.instance`)

iOS maps use `OlaMapService` (api key, tile URL, project id). Native iOS overlay APIs differ slightly from Android (annotations vs markers; bezier/clustering are approximated).

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
Olamaps.instance.initialize('YOUR_OLA_MAPS_API_KEY');

final maps = Olamaps.instance;

final suggestions = await maps.places.getAutocompleteSuggestions(input: 'Koramangala');
final details = await maps.places.getPlaceDetails(placeId: suggestions.first.placeId);
final advanced = await maps.places.getAdvancedPlaceDetails(placeId: details.placeId);
final nearby = await maps.places.getNearBySearchPlaces(
  location: Location(lat: 12.9315, lng: 77.6164),
  types: ['cafe'],
);
await maps.places.validateAddress('7, Lok Kalyan Marg, New Delhi');
await maps.places.getPhoto('photo_reference');

final addresses = await maps.geoencoder.fetchAddresses(
  Location(lat: 12.9313, lng: 77.6165),
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
);
await maps.streetView.nearestImageId(latitude: 12.9345, longitude: 77.6136);

await maps.routing.getDistanceMatrix(
  origins: [Location(lat: 12.93, lng: 77.61)],
  destinations: [Location(lat: 12.97, lng: 77.59)],
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

3. Pass `projectId` (dashboard project / workspace id) and optionally `tileUrl` / `userId` into `OlaMapView`. Default tiles:

`https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json`

Turn-by-turn navigation (`OlaMapNavigationService`) is a separate [Navigation SDK](https://github.com/ola-maps/ios-navigation-sdk) and is not wrapped by `OlaMapView`.

## Example app

```bash
cd example
flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY --dart-define=OLA_MAPS_PROJECT_ID=YOUR_PROJECT_ID
```

The example demos markers, polylines, circles, polygons, bezier curves, clustering, routing, and current location.

## Requirements

- Flutter SDK ≥ 3.3
- Android `minSdk` ≥ 24, Ola Maps Android SDK **1.8.4**
- iOS 15.0+, OlaMapCore **1.0.8** (`OlaMapService`)

## License

MIT — see [LICENSE](LICENSE). Upstream map plugin: [imselmon/ola_maps_flutter](https://github.com/imselmon/ola_maps_flutter). Android SDK: [ola-maps/android-maps-sdk](https://github.com/ola-maps/android-maps-sdk). iOS SDK: [ola-maps/ios-map-sdk](https://github.com/ola-maps/ios-map-sdk).
