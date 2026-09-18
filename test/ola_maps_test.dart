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
}
