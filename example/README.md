# ola_maps example

Android and iOS demo for the `ola_maps` Flutter plugin.

- Android wraps [Ola Maps SDK 1.8.4](https://github.com/ola-maps/android-maps-sdk).
- iOS wraps [OlaMapCore / OlaMapService](https://github.com/ola-maps/ios-map-sdk) (api key, tile URL, project id).

## Run

Get an API key (and iOS project id) from [Ola Maps](https://maps.olakrutrim.com/), then:

```bash
flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY --dart-define=OLA_MAPS_PROJECT_ID=YOUR_PROJECT_ID --dart-define=OLA_MAPS_LANGUAGE=hi
```

Android `minSdk` is 24. The Ola Maps AAR lives at `android/app/libs/OlaMapSdk-1.8.4.aar`.

iOS requires 15.0+. The example `Podfile` pulls `OlaMapCore` from git. Location permission strings are in `ios/Runner/Info.plist`.

The bottom toolbar adds/removes markers, polylines, circles, polygons, bezier curves, clusters, and a directions polyline.
