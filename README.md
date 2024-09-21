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

**Version:** 0.02 
**OAS:** 3.0  
**API Specification:** `/openapi/geocode-oas.yaml`

The OLA Maps - Geocode API package provides a comprehensive suite of tools for geographic data, including functionalities for Forward and Reverse Geocoding, Routing, Roads, Places, and Map Tiles APIs.

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
     ola_maps: ^0.0.2
   ```

2. **Import the package:**

   In your Dart file, import the package:
   ```dart
   import 'package:ola_maps/ola_maps.dart';
   ```

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

// ... (MyApp and MyHomePage classes as shown in your example) ...
```

### Additional APIs

- **Routing API:** Provides directions and route optimization between locations.
- **Roads API:** Retrieves road segment information and calculates distance.
- **Places API:** Searches and retrieves details about places.
- **Map Tiles API:** Retrieves tiles for visual representation.

Refer to the API documentation in `/openapi/geocode-oas.yaml` for more details on using these additional APIs.

## Troubleshooting

If you encounter a `500 Internal Server Error` when calling the APIs, please ensure:

1. **API Key:** Your API key is valid and properly initialized.
2. **Project Link:** Ensure your project is linked to an OLA Maps subscription. This can often resolve access issues.

For detailed API documentation, see `/openapi/geocode-oas.yaml`.

## Additional Information

- **Documentation:** For detailed API documentation, see `/openapi/geocode-oas.yaml`.
- **Example Project:** An example project demonstrating usage is included.
- **Contributing:** Contributions are welcome! Please refer to the `CONTRIBUTING.md` file for guidelines.
- **Issues:** To report issues or bugs, please use the [Issues tracker](#) on GitHub.

Feel free to reach out for any questions or support.
```

### Key Changes:
1. **Structured Initialization Section:** Added clarity to the API key initialization step.
2. **Troubleshooting Section:** Included a clear explanation of the common error (500) and potential solutions.
3. **Consistent Formatting:** Ensured the README follows a consistent style for improved readability.