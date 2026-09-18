# ola_maps example

Android demo for the `ola_maps` Flutter plugin wrapping [Ola Maps SDK 1.8.4](https://github.com/ola-maps/android-maps-sdk).

## Run

Get an API key from [Ola Maps](https://maps.olakrutrim.com/), then:

```bash
flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY
```

`minSdk` is 24. The Ola Maps AAR lives at `android/app/libs/OlaMapSdk-1.8.4.aar`.

The bottom toolbar adds/removes markers, polylines, circles, polygons, bezier curves, clusters, and a directions polyline.
