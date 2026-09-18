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
  final Map<String, dynamic>? openingHours;
  final String? businessStatus;
  final String? url;
  final String? formattedPhoneNumber;
  final String? internationalPhoneNumber;
  final String? website;
  final List<dynamic> photos;
  final num? rating;
  final List<dynamic> amenitiesAvailable;
  final dynamic wheelchairAccessibility;
  final dynamic parkingAvailable;
  final dynamic isLandmark;
  final String? landmarkType;
  final String? paymentMode;
  final List<dynamic> popularItems;
  final dynamic languageSpoken;

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
    this.openingHours,
    this.businessStatus,
    this.url,
    this.formattedPhoneNumber,
    this.internationalPhoneNumber,
    this.website,
    this.photos = const [],
    this.rating,
    this.amenitiesAvailable = const [],
    this.wheelchairAccessibility,
    this.parkingAvailable,
    this.isLandmark,
    this.landmarkType,
    this.paymentMode,
    this.popularItems = const [],
    this.languageSpoken,
  });

  factory NearByPlaceDetails.fromJson(Map<String, dynamic> json) {
    List<String> asStrings(dynamic value) {
      if (value is List) return value.map((item) => item.toString()).toList();
      if (value is String && value.isNotEmpty) return [value];
      return const [];
    }

    return NearByPlaceDetails(
      description: json['description']?.toString() ?? '',
      matchedSubstrings: json['matched_substrings'] as List? ?? const [],
      placeId: json['place_id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      structuredFormatting: StructuredFormatting.fromJson(
        Map<String, dynamic>.from(
          json['structured_formatting'] as Map? ?? const {},
        ),
      ),
      terms: ((json['terms'] as List?) ?? const [])
          .map((e) => Term.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      types: asStrings(json['types']),
      layer: asStrings(json['layer']),
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      openingHours: json['opening_hours'] is Map
          ? Map<String, dynamic>.from(json['opening_hours'] as Map)
          : null,
      businessStatus: json['business_status']?.toString(),
      url: json['url']?.toString(),
      formattedPhoneNumber: json['formatted_phone_number']?.toString(),
      internationalPhoneNumber: json['international_phone_number']?.toString(),
      website: json['website']?.toString(),
      photos: json['photos'] as List? ?? const [],
      rating: json['rating'] as num?,
      amenitiesAvailable: json['amenities_available'] as List? ?? const [],
      wheelchairAccessibility: json['wheelchair_accessibility'],
      parkingAvailable: json['parking_available'],
      isLandmark: json['is_landmark'],
      landmarkType: json['landmark_type']?.toString(),
      paymentMode: json['payment_mode']?.toString(),
      popularItems: json['popular_items'] as List? ?? const [],
      languageSpoken: json['language_spoken'],
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
      'opening_hours': openingHours,
      'business_status': businessStatus,
      'url': url,
      'formatted_phone_number': formattedPhoneNumber,
      'international_phone_number': internationalPhoneNumber,
      'website': website,
      'photos': photos,
      'rating': rating,
      'amenities_available': amenitiesAvailable,
      'wheelchair_accessibility': wheelchairAccessibility,
      'parking_available': parkingAvailable,
      'is_landmark': isLandmark,
      'landmark_type': landmarkType,
      'payment_mode': paymentMode,
      'popular_items': popularItems,
      'language_spoken': languageSpoken,
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
      mainText: json['main_text']?.toString() ?? '',
      mainTextMatchedSubstrings: json['main_text_matched_substrings'] ?? [],
      secondaryText: json['secondary_text']?.toString() ?? '',
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
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'value': value,
    };
  }
}
