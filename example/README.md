# ola_maps example

Android, iOS, and web demo for the `ola_maps` Flutter plugin.

- Android wraps [Ola Maps SDK 1.8.4](https://github.com/ola-maps/android-maps-sdk).
- iOS wraps [OlaMapCore / OlaMapService](https://github.com/ola-maps/ios-map-sdk) (api key, tile URL, project id).
- Web wraps [Ola Maps Web SDK v2](https://maps.olakrutrim.com/krutrim/docs/sdks/web-sdk/latest/setup) (`olamaps-web-sdk`).

## Run

Get an API key (and iOS project id) from [Ola Maps](https://maps.olakrutrim.com/), then:

```bash
flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY --dart-define=OLA_MAPS_PROJECT_ID=YOUR_PROJECT_ID --dart-define=OLA_MAPS_LANGUAGE=hi
```

Android `minSdk` is 24. The Ola Maps AAR lives at `android/app/libs/OlaMapSdk-1.8.4.aar`.

iOS requires 15.0+. The plugin uses Swift Package Manager (`ios/ola_maps/Package.swift`) and embeds every OlaMapCore xcframework, including MoEngageCards. Location permission strings are in `ios/Runner/Info.plist`.

Web loads `olamaps-web-sdk` from UNPKG in `web/index.html`. Run with `-d chrome`.

The bottom toolbar adds/removes markers, polylines, circles, polygons, bezier curves, clusters, and a directions polyline.
