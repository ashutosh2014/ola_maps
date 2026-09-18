import 'package:ola_maps/src/utilities/models.dart';

class AutoCompleteResults {
  final String reference;
  final List<String> types;
  final List<MatchedSubstring> matchedSubstrings;
  final int? distanceMeters;
  final List<Term> terms;
  final StructuredFormatting structuredFormatting;
  final String description;
  final Location geometry;
  final String placeId;

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
          .map((e) => MatchedSubstring.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      terms: ((json['terms'] as List?) ?? const [])
          .map((e) => Term.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      structuredFormatting: StructuredFormatting.fromJson(
        Map<String, dynamic>.from(
          json['structured_formatting'] as Map? ?? const {},
        ),
      ),
      description: json['description']?.toString() ?? '',
      geometry: Location.fromJson(
        Map<String, dynamic>.from(
          (json['geometry'] is Map ? json['geometry']['location'] : null)
                  as Map? ??
              const {},
        ),
      ),
      placeId: json['place_id']?.toString() ?? '',
    );
  }

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

  @override
  String toString() {
    return 'AutoCompleteResults{reference: $reference, description: $description, distanceMeters: $distanceMeters}';
  }
}

class MatchedSubstring {
  final int offset;
  final int length;

  MatchedSubstring({
    required this.offset,
    required this.length,
  });

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) {
    return MatchedSubstring(
      offset: json['offset'],
      length: json['length'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'length': length,
    };
  }
}
