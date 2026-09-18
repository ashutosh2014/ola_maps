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

class MatchedSubstring {
  final int offset;
  final int length;

  MatchedSubstring({
    required this.offset,
    required this.length,
  });

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) {
    return MatchedSubstring(
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      length: (json['length'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'length': length,
    };
  }
}
