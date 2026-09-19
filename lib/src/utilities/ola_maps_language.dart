/// ISO 639-1 language codes supported by Ola Maps Places, Routing, Geocoding,
/// and Maps APIs. Defaults to [en] when omitted.
class OlaMapsLanguage {
  const OlaMapsLanguage._(this.code, this.name, this.script, this.example);

  /// ISO 639-1 code (`en`, `hi`, …).
  final String code;

  /// English display name.
  final String name;

  /// Writing system used by this language.
  final String script;

  /// Sample localized place-type string.
  final String example;

  /// English (`en`).
  static const en = OlaMapsLanguage._('en', 'English', 'Latin', 'Restaurant');

  /// Hindi (`hi`).
  static const hi = OlaMapsLanguage._('hi', 'Hindi', 'Devanagari', 'रेस्टोरेंट');

  /// Kannada (`kn`).
  static const kn = OlaMapsLanguage._('kn', 'Kannada', 'Kannada', 'ರೆಸ್ಟೋರೆಂಟ್');

  /// Telugu (`te`).
  static const te = OlaMapsLanguage._('te', 'Telugu', 'Telugu', 'రెస్టారెంట్');

  /// Tamil (`ta`).
  static const ta = OlaMapsLanguage._('ta', 'Tamil', 'Tamil', 'உணவகம்');

  /// Malayalam (`ml`).
  static const ml = OlaMapsLanguage._('ml', 'Malayalam', 'Malayalam', 'റെസ്റ്റോറന്റ്');

  /// Sanskrit (`sa`).
  static const sa = OlaMapsLanguage._('sa', 'Sanskrit', 'Devanagari', 'भोजनालयः');

  /// Bengali (`bn`).
  static const bn = OlaMapsLanguage._('bn', 'Bengali', 'Bengali', 'রেস্তোরাঁ');

  /// Gujarati (`gu`).
  static const gu = OlaMapsLanguage._('gu', 'Gujarati', 'Gujarati', 'રેસ્ટોરન્ટ');

  /// Marathi (`mr`).
  static const mr = OlaMapsLanguage._('mr', 'Marathi', 'Devanagari', 'उपहारगृह');

  /// Odia (`or`).
  static const or = OlaMapsLanguage._('or', 'Odia', 'Odia', 'ରେଷ୍ଟୁରାଣ୍ଟ');

  /// Urdu (`ur`).
  static const ur = OlaMapsLanguage._('ur', 'Urdu', 'Arabic', 'ریستوراں');

  /// Alias for [en].
  static const english = en;

  /// Alias for [hi].
  static const hindi = hi;

  /// Alias for [kn].
  static const kannada = kn;

  /// Alias for [te].
  static const telugu = te;

  /// Alias for [ta].
  static const tamil = ta;

  /// Alias for [ml].
  static const malayalam = ml;

  /// Alias for [sa].
  static const sanskrit = sa;

  /// Alias for [bn].
  static const bengali = bn;

  /// Alias for [gu].
  static const gujarati = gu;

  /// Alias for [mr].
  static const marathi = mr;

  /// Alias for [or].
  static const odia = or;

  /// Alias for [ur].
  static const urdu = ur;

  /// Every supported [OlaMapsLanguage].
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

  /// Lookup table keyed by ISO 639-1 code.
  static final Map<String, OlaMapsLanguage> byCode = {
    for (final language in values) language.code: language,
  };

  /// Default ISO 639-1 code (`en`).
  static const defaultCode = 'en';

  /// Light vector style id without a language suffix.
  static const lightStandardStyle = 'default-light-standard';

  /// Dark vector style id without a language suffix.
  static const darkStandardStyle = 'default-dark-standard';

  /// Two-letter code for query/body `language`. Unknown values are kept as-is
  /// (lowercased). Null/empty becomes English.
  static String codeOf(Object? language, {String fallback = defaultCode}) {
    if (language is OlaMapsLanguage) return language.code;
    final raw = language?.toString().trim().toLowerCase();
    if (raw == null || raw.isEmpty) return fallback;
    return raw;
  }

  /// Whether [language] is one of the 12 dashboard-supported codes.
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

  /// Full `style.json` URL for [language] (light or [dark]).
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
