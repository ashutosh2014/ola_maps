import 'package:flutter/services.dart';

/// Path marker used by apps that hide the Ola API key behind their own backend.
///
/// A tile URL such as `https://api.example.com/ola-maps/styles/...` is rewritten
/// on Android to `{origin}/ola-maps/proxy` (see `OlaMapsHttpProxy`).
const String kOlaMapsBackendProxyPath = '/ola-maps/';

const _placeholderApiKeys = {
  'YOUR_API_KEY',
  'YOUR_OLA_MAPS_API_KEY',
  '<API KEY>',
};

/// Returns `false` for empty or placeholder dashboard keys.
bool isOlaMapsApiKeyConfigured(String apiKey) {
  final key = apiKey.trim();
  if (key.isEmpty) return false;
  return !_placeholderApiKeys.contains(key);
}

/// True when [tileUrl] is served through an app backend that hides the API key.
/// Matches Android `OlaMapsHttpProxy.usesBackendProxy`.
bool usesOlaMapsBackendProxy(String? tileUrl) {
  return olaMapsBackendProxyBase(tileUrl) != null;
}

/// `{origin}/ola-maps/proxy` derived from a tile URL, or null if unused.
String? olaMapsBackendProxyBase(String? tileUrl) {
  final url = tileUrl?.trim() ?? '';
  if (url.isEmpty) return null;
  final index = url.indexOf(kOlaMapsBackendProxyPath);
  if (index < 0) return null;
  return '${url.substring(0, index)}/ola-maps/proxy';
}

/// The map can start with a real dashboard key **or** a backend tile proxy.
bool canCreateOlaMapView({
  required String apiKey,
  required String tileUrl,
}) {
  return isOlaMapsApiKeyConfigured(apiKey) || usesOlaMapsBackendProxy(tileUrl);
}

/// Turns native / HTTP failures into a short message for [OlaMapView.onMapError].
String formatOlaMapError(Object error) {
  final raw = error is PlatformException
      ? (error.message ?? error.code)
      : error.toString();
  if (raw.contains('403')) {
    return 'Ola Maps rejected the style request (HTTP 403). '
        'Use a real API key from https://maps.olakrutrim.com/ and run:\n'
        'flutter run --dart-define=OLA_MAPS_API_KEY=YOUR_KEY';
  }
  if (raw.contains('401')) {
    return 'Ola Maps authentication failed (HTTP 401). Check the API key.';
  }
  return raw;
}
