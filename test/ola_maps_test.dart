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
}
