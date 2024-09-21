class NearByPlaceDetails {
  final String description;
  final List<dynamic> matchedSubstrings;
  final String placeId;
  final String reference;
  final StructuredFormatting structuredFormatting;
  final List<Term> terms;
  final List<String> types;
  final List<String> layer;
  final int? distanceMeters;

  NearByPlaceDetails({
    required this.description,
    required this.matchedSubstrings,
    required this.placeId,
    required this.reference,
    required this.structuredFormatting,
    required this.terms,
    required this.types,
    required this.layer,
    required this.distanceMeters,
  });

  factory NearByPlaceDetails.fromJson(Map<String, dynamic> json) {
    return NearByPlaceDetails(
      description: json['description'],
      matchedSubstrings: json['matched_substrings'] ?? [],
      placeId: json['place_id'],
      reference: json['reference'],
      structuredFormatting:
          StructuredFormatting.fromJson(json['structured_formatting']),
      terms: (json['terms'] as List).map((e) => Term.fromJson(e)).toList(),
      types: List<String>.from(json['types']),
      layer: List<String>.from(json['layer']),
      distanceMeters: json['distance_meters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'matched_substrings': matchedSubstrings,
      'place_id': placeId,
      'reference': reference,
      'structured_formatting': structuredFormatting.toJson(),
      'terms': terms.map((e) => e.toJson()).toList(),
      'types': types,
      'layer': layer,
      'distance_meters': distanceMeters,
    };
  }

  @override
  String toString() {
    return 'NearByPlaceDetails{description: $description, placeId: $placeId, distanceMeters: $distanceMeters}';
  }
}

class StructuredFormatting {
  final String mainText;
  final List<dynamic> mainTextMatchedSubstrings;
  final String secondaryText;
  final List<dynamic> secondaryTextMatchedSubstrings;

  StructuredFormatting({
    required this.mainText,
    required this.mainTextMatchedSubstrings,
    required this.secondaryText,
    required this.secondaryTextMatchedSubstrings,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'],
      mainTextMatchedSubstrings: json['main_text_matched_substrings'] ?? [],
      secondaryText: json['secondary_text'],
      secondaryTextMatchedSubstrings:
          json['secondary_text_matched_substrings'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main_text': mainText,
      'main_text_matched_substrings': mainTextMatchedSubstrings,
      'secondary_text': secondaryText,
      'secondary_text_matched_substrings': secondaryTextMatchedSubstrings,
    };
  }
}

class Term {
  final int offset;
  final String value;

  Term({
    required this.offset,
    required this.value,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      offset: json['offset'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'value': value,
    };
  }
}
