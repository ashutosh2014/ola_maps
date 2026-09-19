import 'package:flutter_test/flutter_test.dart';
import 'package:ola_maps/ola_maps.dart';

void main() {
  test('OlaLatLng serializes coordinates', () {
    const point = OlaLatLng(18.52, 73.93);
    expect(point.toJson(), {
      'latitude': 18.52,
      'longitude': 73.93,
    });
    expect(OlaLatLng.fromJson(point.toJson()), point);
  });

  test('OlaLineType exposes SDK line styles', () {
    expect(OlaLineType.solid, 'LINE_SOLID');
    expect(OlaLineType.dotted, 'LINE_DOTTED');
  });

  test('formatOlaMapError explains HTTP 403', () {
    expect(
      formatOlaMapError('loading style failed: HTTP status code 403'),
      contains('OLA_MAPS_API_KEY'),
    );
  });

  test('placeholder API keys are rejected', () {
    expect(isOlaMapsApiKeyConfigured('YOUR_API_KEY'), isFalse);
    expect(isOlaMapsApiKeyConfigured('abc123'), isTrue);
  });

  test('backend tile proxy is detected from the tile URL path', () {
    expect(usesOlaMapsBackendProxy(kOlaMapsDefaultTileUrl), isFalse);
    expect(usesOlaMapsBackendProxy('https://api.example.com/styles.json'), isFalse);
    expect(
      usesOlaMapsBackendProxy(
        'https://api.example.com/ola-maps/styles/default/style.json',
      ),
      isTrue,
    );
    expect(
      olaMapsBackendProxyBase(
        'https://api.example.com/ola-maps/styles/default/style.json',
      ),
      'https://api.example.com/ola-maps/proxy',
    );
    expect(
      canCreateOlaMapView(apiKey: 'YOUR_API_KEY', tileUrl: kOlaMapsDefaultTileUrl),
      isFalse,
    );
    expect(
      canCreateOlaMapView(
        apiKey: '',
        tileUrl: 'https://api.example.com/ola-maps/style.json',
      ),
      isTrue,
    );
  });

  test('OlaMapsLanguage maps ISO codes and dynamic map styles', () {
    expect(OlaMapsLanguage.codeOf(null), 'en');
    expect(OlaMapsLanguage.codeOf(OlaMapsLanguage.hi), 'hi');
    expect(OlaMapsLanguage.codeOf('TA'), 'ta');
    expect(OlaMapsLanguage.isSupported('ml'), isTrue);
    expect(OlaMapsLanguage.mapStyleName(), 'default-light-standard');
    expect(
      OlaMapsLanguage.mapStyleName(language: OlaMapsLanguage.ml),
      'default-light-standard-ml',
    );
    expect(
      OlaMapsLanguage.dynamicMapStyleUrl(language: 'ml'),
      'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard-ml/style.json',
    );
    expect(
      OlaMapsLanguage.resolveTileUrl(
        kOlaMapsDefaultTileUrl,
        language: 'hi',
      ),
      'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard-hi/style.json',
    );
    expect(
      OlaMapsLanguage.resolveTileUrl(
        'https://example.com/custom.json',
        language: 'hi',
      ),
      'https://example.com/custom.json',
    );
  });

  test('web SDK constants match Ola Maps CDN URLs', () {
    expect(
      kOlaMapsWebSdkUrl,
      contains('olamaps-web-sdk'),
    );
    expect(
      kOlaMapsDefaultThreeDTileset,
      contains('3dtiles/tileset.json'),
    );
  });

  test('AutoCompleteResults parses nested and flat geometry', () {
    final nested = AutoCompleteResults.fromJson({
      'description': 'Phoenix Mall, Pune',
      'place_id': 'ola-platform:abc',
      'geometry': {
        'location': {'lat': 18.5622, 'lng': 73.9168},
      },
      'structured_formatting': {
        'main_text': 'Phoenix Mall',
        'secondary_text': 'Pune',
      },
    });
    expect(nested.description, 'Phoenix Mall, Pune');
    expect(nested.geometry.hasCoordinates, isTrue);
    expect(nested.geometry.lat, 18.5622);

    final flat = AutoCompleteResults.fromJson({
      'formatted_address': 'Koregaon Park',
      'lat': 18.5362,
      'lng': 73.8938,
    });
    expect(flat.description, 'Koregaon Park');
    expect(flat.geometry.lng, 73.8938);

    expect(flattenPredictions({'0': {'a': 1}}), isNotEmpty);
    expect(parseStatus('REQUEST_DENIED'), Status.badRequest);
    expect(parseStatus('something-new'), Status.ok);
  });
}
