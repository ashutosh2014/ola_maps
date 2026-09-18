/// ISO 639-1 language codes supported by Ola Maps Places, Routing, Geocoding,
/// and Maps APIs. Defaults to [en] when omitted.
class OlaMapsLanguage {
  const OlaMapsLanguage._(this.code, this.name, this.script, this.example);

  final String code;
  final String name;
  final String script;
  final String example;

  static const en = OlaMapsLanguage._('en', 'English', 'Latin', 'Restaurant');
  static const hi = OlaMapsLanguage._('hi', 'Hindi', 'Devanagari', 'रेस्टोरेंट');
  static const kn = OlaMapsLanguage._('kn', 'Kannada', 'Kannada', 'ರೆಸ್ಟೋರೆಂಟ್');
  static const te = OlaMapsLanguage._('te', 'Telugu', 'Telugu', 'రెస్టారెంట్');
  static const ta = OlaMapsLanguage._('ta', 'Tamil', 'Tamil', 'உணவகம்');
  static const ml = OlaMapsLanguage._('ml', 'Malayalam', 'Malayalam', 'റെസ്റ്റോറന്റ്');
  static const sa = OlaMapsLanguage._('sa', 'Sanskrit', 'Devanagari', 'भोजनालयः');
  static const bn = OlaMapsLanguage._('bn', 'Bengali', 'Bengali', 'রেস্তোরাঁ');
  static const gu = OlaMapsLanguage._('gu', 'Gujarati', 'Gujarati', 'રેસ્ટોરન્ટ');
  static const mr = OlaMapsLanguage._('mr', 'Marathi', 'Devanagari', 'उपहारगृह');
  static const or = OlaMapsLanguage._('or', 'Odia', 'Odia', 'ରେଷ୍ଟୁରାଣ୍ଟ');
  static const ur = OlaMapsLanguage._('ur', 'Urdu', 'Arabic', 'ریستوراں');

  static const english = en;
  static const hindi = hi;
  static const kannada = kn;
  static const telugu = te;
  static const tamil = ta;
  static const malayalam = ml;
  static const sanskrit = sa;
  static const bengali = bn;
  static const gujarati = gu;
  static const marathi = mr;
  static const odia = or;
  static const urdu = ur;

  static const values = <OlaMapsLanguage>[
    en,
    hi,
    kn,
    te,
    ta,
    ml,
    sa,
    bn,
    gu,
    mr,
    or,
    ur,
  ];

  static final Map<String, OlaMapsLanguage> byCode = {
    for (final language in values) language.code: language,
  };

  static const defaultCode = 'en';
  static const lightStandardStyle = 'default-light-standard';
  static const darkStandardStyle = 'default-dark-standard';

  /// Two-letter code for query/body `language`. Unknown values are kept as-is
  /// (lowercased). Null/empty becomes English.
  static String codeOf(Object? language, {String fallback = defaultCode}) {
    if (language is OlaMapsLanguage) return language.code;
    final raw = language?.toString().trim().toLowerCase();
    if (raw == null || raw.isEmpty) return fallback;
    return raw;
  }

  static bool isSupported(Object? language) {
    return byCode.containsKey(codeOf(language));
  }

  /// Dynamic/static map style id. English uses `default-light-standard`;
  /// other languages append `-{code}` (e.g. `default-light-standard-ml`).
  static String mapStyleName({
    Object? language,
    bool dark = false,
    String? baseStyle,
  }) {
    var base = baseStyle ?? (dark ? darkStandardStyle : lightStandardStyle);
    final code = codeOf(language);
    for (final supported in values) {
      if (supported.code == defaultCode) continue;
      final suffix = '-${supported.code}';
      if (base.endsWith(suffix)) {
        base = base.substring(0, base.length - suffix.length);
        break;
      }
    }
    if (code == defaultCode) return base;
    return '$base-$code';
  }

  static String dynamicMapStyleUrl({
    Object? language,
    bool dark = false,
    String? baseStyle,
  }) {
    final style = mapStyleName(
      language: language,
      dark: dark,
      baseStyle: baseStyle,
    );
    return 'https://api.olamaps.io/tiles/vector/v1/styles/$style/style.json';
  }

  /// Prefer a caller-supplied tile URL unless it is the default English style
  /// and a non-English [language] was requested.
  static String resolveTileUrl(
    String? tileUrl, {
    Object? language,
    bool dark = false,
  }) {
    final code = codeOf(language);
    final fallback = dynamicMapStyleUrl(language: code, dark: dark);
    if (tileUrl == null || tileUrl.trim().isEmpty) return fallback;
    final trimmed = tileUrl.trim();
    final englishDefault = dynamicMapStyleUrl(language: defaultCode, dark: dark);
    if (code != defaultCode && trimmed == englishDefault) return fallback;
    return trimmed;
  }
}
