import 'package:ola_maps/src/utilities/models.dart';

/// One Places Autocomplete suggestion.
class AutoCompleteResults {
  /// Alternate place reference token.
  final String reference;

  /// Place-type tags.
  final List<String> types;

  /// Ranges inside [description] that matched the query.
  final List<MatchedSubstring> matchedSubstrings;

  /// Distance from the bias location, in meters.
  final int? distanceMeters;

  /// Tokenized description parts.
  final List<Term> terms;

  /// Bold/main and secondary labels.
  final StructuredFormatting structuredFormatting;

  /// Full suggestion text.
  final String description;

  /// Coordinate when the API included geometry.
  final Location geometry;

  /// Ola Maps place id.
  final String placeId;

  /// Creates an autocomplete row.
  AutoCompleteResults({
    required this.reference,
    required this.types,
    required this.matchedSubstrings,
    required this.distanceMeters,
    required this.terms,
    required this.structuredFormatting,
    required this.description,
    required this.geometry,
    required this.placeId,
  });

  /// Parses an autocomplete prediction JSON object.
  factory AutoCompleteResults.fromJson(Map<String, dynamic> json) {
    List<String> asStrings(dynamic value) {
      if (value is List) return value.map((item) => item.toString()).toList();
      if (value is String && value.isNotEmpty) return [value];
      return const [];
    }

    return AutoCompleteResults(
      reference: json['reference']?.toString() ?? '',
      types: asStrings(json['types']),
      matchedSubstrings: ((json['matched_substrings'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => MatchedSubstring.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      terms: ((json['terms'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Term.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      structuredFormatting: StructuredFormatting.fromJson(
        Map<String, dynamic>.from(
          json['structured_formatting'] as Map? ?? const {},
        ),
      ),
      description: json['description']?.toString() ??
          json['formatted_address']?.toString() ??
          json['name']?.toString() ??
          '',
      geometry: locationFromPrediction(json),
      placeId: json['place_id']?.toString() ?? json['id']?.toString() ?? '',
    );
  }

  /// Serializes this suggestion.
  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'types': types,
      'matched_substrings': matchedSubstrings.map((e) => e.toJson()).toList(),
      'distance_meters': distanceMeters,
      'terms': terms.map((e) => e.toJson()).toList(),
      'structured_formatting': structuredFormatting.toJson(),
      'description': description,
      'geometry': geometry.toJson(),
      'place_id': placeId,
    };
  }

  /// Reads `geometry.location`, flat `location`, or top-level lat/lng.
  static Location locationFromPrediction(Map<String, dynamic> json) {
    Map<String, dynamic>? loc;
    final geometry = json['geometry'];
    if (geometry is Map) {
      final nested = geometry['location'];
      if (nested is Map) {
        loc = Map<String, dynamic>.from(nested);
      } else if (geometry.containsKey('lat') ||
          geometry.containsKey('lng') ||
          geometry.containsKey('latitude') ||
          geometry.containsKey('longitude')) {
        loc = Map<String, dynamic>.from(geometry);
      }
    }
    final top = json['location'];
    if (loc == null && top is Map) {
      loc = Map<String, dynamic>.from(top);
    }
    loc ??= {
      'lat': json['lat'] ?? json['latitude'],
      'lng': json['lng'] ?? json['longitude'],
    };
    return Location.fromJson(loc);
  }

  @override
  String toString() {
    return 'AutoCompleteResults{reference: $reference, description: $description, distanceMeters: $distanceMeters}';
  }
}

/// Character range that matched an autocomplete query.
class MatchedSubstring {
  /// Start index in the description.
  final int offset;

  /// Match length.
  final int length;

  /// Creates a match range.
  MatchedSubstring({
    required this.offset,
    required this.length,
  });

  /// Parses `{offset, length}`.
  factory MatchedSubstring.fromJson(Map<String, dynamic> json) {
    return MatchedSubstring(
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      length: (json['length'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializes this range.
  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'length': length,
    };
  }
}
