Great, I’ve incorporated the example code into the README. Here’s the updated version:

---

<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# OLA Maps - Geocode API

**Version:** 1.0.0  
**OAS:** 3.0  
**API Specification:** `/openapi/geocode-oas.yaml`

The OLA Maps - Geocode API package provides a comprehensive suite of tools for geographic data. It includes functionalities for Forward and Reverse Geocoding, Routing, Roads, Places, and Map Tiles APIs.

## Features

- **Forward Geocode API:** Converts addresses or place names into geographic coordinates (latitude and longitude).
- **Reverse Geocode API:** Converts geographic coordinates back into human-readable addresses or place names.
- **Routing API:** Provides directions and route optimization between multiple locations.
- **Roads API:** Retrieves information about road segments and calculates distance along roads.
- **Places API:** Searches for and provides details about places of interest.
- **Map Tiles API:** Retrieves map tiles for visual representation of geographic areas.

## Getting Started

To use this package, you'll need to set up your project and include your OLA Maps API key.

1. **Add the dependency:**

   Add `ola_maps` to your `pubspec.yaml` file:
   ```yaml
   dependencies:
     ola_maps: ^1.0.0
   ```

2. **Import the package:**

   In your Dart file, import the package:
   ```dart
   import 'package:ola_maps/ola_maps.dart';
   ```

## Usage

### Initialization

Initialize the OLA Maps instance with your API key before using any API:

```dart
void main() {
  Olamaps.instance.initialize('YOUR_API_KEY_HERE');
  runApp(const MyApp());
}
```

### Example

Here’s a complete example demonstrating how to use the Geocoding API with a Flutter application:

```dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ola_maps/ola_maps.dart';

void main() {
  Olamaps.instance.initialize('YOUR_API_KEY_HERE');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ola Maps Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ola Maps Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  var result = await Olamaps.instance.geoencoder.fetchLocation(
                    'Ola Electric, 2, Hosur Rd, Koramangala Industrial Layout, Koramangala, Bengaluru, 560095, Karnataka',
                  );
                  for (var address in result) {
                    log("Addresses:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: Text('Test Geoencode'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result = await Olamaps.instance.geoencoder.fetchAddresses(
                    Location(lng: 77.5526110768168, lat: 12.923946516889448),
                  );
                  for (var address in result) {
                    log("Addresses:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: Text('Test Reverse Geoencode'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Additional APIs

- **Routing API:** Provides directions and route optimization between locations.
- **Roads API:** Retrieves road segment information and calculates distance.
- **Places API:** Searches and retrieves details about places.
- **Map Tiles API:** Retrieves tiles for visual representation.

Refer to the API documentation in `/openapi/geocode-oas.yaml` for more details on using these additional APIs.

## Additional Information

- **Documentation:** For detailed API documentation, see `/openapi/geocode-oas.yaml`.
- **Example Project:** An example project demonstrating usage is attached.
- **Contributing:** Contributions are welcome! Please refer to the `CONTRIBUTING.md` file for guidelines.
- **Issues:** To report issues or bugs, please use the [Issues tracker](#) on GitHub.

Feel free to reach out for any questions or support.

---

Let me know if there's anything else you need!