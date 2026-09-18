export 'near_by_place_details.dart';
export 'auto_complete_results.dart';

class Address {
  String formattedAddress;
  List<String> types;
  String name;
  Geometry geometry;
  List<AddressComponent> addressComponents;
  PlusCode plusCode;
  String placeId;
  List<String> layer;

  Address({
    required this.formattedAddress,
    required this.types,
    required this.name,
    required this.geometry,
    required this.addressComponents,
    required this.plusCode,
    required this.placeId,
    required this.layer,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    final components = json['address_components'] as List? ?? const [];
    return Address(
      formattedAddress: json['formatted_address']?.toString() ?? '',
      types: List<String>.from(json['types'] ?? const []),
      name: json['name']?.toString() ??
          json['formatted_address']?.toString() ??
          '',
      geometry: Geometry.fromJson(
        Map<String, dynamic>.from(json['geometry'] as Map? ?? const {}),
      ),
      addressComponents: components
          .map((item) => AddressComponent.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      plusCode: json['plus_code'] is Map
          ? PlusCode.fromJson(Map<String, dynamic>.from(json['plus_code'] as Map))
          : PlusCode(compoundCode: '', globalCode: ''),
      placeId: json['place_id']?.toString() ?? '',
      layer: List<String>.from(json['layer'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatted_address': formattedAddress,
      'types': types,
      'name': name,
      'geometry': geometry.toJson(),
      'address_components': addressComponents.map((v) => v.toJson()).toList(),
      'plus_code': plusCode.toJson(),
      'place_id': placeId,
      'layer': layer,
    };
  }
}

class Geometry {
  Viewport viewport;
  Location location;
  String? locationType;

  Geometry({
    required this.viewport,
    required this.location,
    required this.locationType,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) {
    final locationJson = Map<String, dynamic>.from(
      json['location'] as Map? ?? const {'lat': 0, 'lng': 0},
    );
    final location = Location.fromJson(locationJson);
    return Geometry(
      viewport: json['viewport'] is Map
          ? Viewport.fromJson(Map<String, dynamic>.from(json['viewport'] as Map))
          : Viewport(southwest: location, northeast: location),
      location: location,
      locationType: json['location_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewport': viewport.toJson(),
      'location': location.toJson(),
      'location_type': locationType,
    };
  }
}

class Viewport {
  Location southwest;
  Location northeast;

  Viewport({
    required this.southwest,
    required this.northeast,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      southwest: Location.fromJson(json['southwest']),
      northeast: Location.fromJson(json['northeast']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'southwest': southwest.toJson(),
      'northeast': northeast.toJson(),
    };
  }
}

class Location {
  double lng;
  double lat;

  Location({
    required this.lng,
    required this.lat,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lng: (json['lng'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble() ??
          0,
      lat: (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble() ??
          0,
    );
  }

  bool get hasCoordinates => lat != 0 || lng != 0;

  Map<String, dynamic> toJson() {
    return {
      'lng': lng,
      'lat': lat,
    };
  }

  @override
  String toString() {
    return '$lat,$lng';
  }
}

class AddressComponent {
  List<String> types;
  String shortName;
  String longName;

  AddressComponent({
    required this.types,
    required this.shortName,
    required this.longName,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      types: List<String>.from(json['types'] ?? const []),
      shortName: json['short_name']?.toString() ?? '',
      longName: json['long_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'types': types,
      'short_name': shortName,
      'long_name': longName,
    };
  }
}

class PlusCode {
  String compoundCode;
  String globalCode;

  PlusCode({
    required this.compoundCode,
    required this.globalCode,
  });

  factory PlusCode.fromJson(Map<String, dynamic> json) {
    return PlusCode(
      compoundCode: json['compound_code']?.toString() ?? '',
      globalCode: json['global_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compound_code': compoundCode,
      'global_code': globalCode,
    };
  }
}

class TextSearchPrediction {
  final String formattedAddress;
  final Location geometry;
  final String placeId;
  final String name;
  final List<String> types;

  TextSearchPrediction({
    required this.formattedAddress,
    required this.geometry,
    required this.placeId,
    required this.name,
    required this.types,
  });

  factory TextSearchPrediction.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final locationJson = geometry is Map ? geometry['location'] : null;
    return TextSearchPrediction(
      formattedAddress: json['formatted_address']?.toString() ?? '',
      geometry: Location.fromJson(
        Map<String, dynamic>.from(locationJson as Map? ?? const {}),
      ),
      placeId: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      types: List<String>.from(json['types'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatted_address': formattedAddress,
      'geometry': geometry.toJson(),
      'place_id': placeId,
      'name': name,
      'types': types,
    };
  }

  @override
  String toString() {
    return 'Place(formattedAddress: $formattedAddress, geometry: $geometry, placeId: $placeId, name: $name, types: $types)';
  }
}

class PlaceDetails {
  final List<AddressComponent> addressComponents;
  final String formattedAddress;
  final Geometry geometry;
  final String placeId;
  final String reference;
  final String businessStatus;
  final String formattedPhoneNumber;
  final String icon;
  final String iconBackgroundColor;
  final String iconMaskBaseUri;
  final String internationalPhoneNumber;
  final String name;
  final OpeningHours openingHours;
  final PlusCode plusCode;
  final double rating;
  final List<Review> reviews;
  final List<String> types;
  final List<String> layer;
  final String url;
  final int userRatingsTotal;
  final int utcOffset;
  final String vicinity;
  final String website;
  final String priceLevel;
  final List<dynamic> photos;
  final String adrAddress;
  final List<dynamic> amenitiesAvailable;
  final bool wheelchairAccessibility;
  final bool parkingAvailable;
  final bool isLandmark;
  final String landmarkType;
  final String paymentMode;
  final List<dynamic> popularItems;
  final dynamic languageSpoken;

  PlaceDetails({
    required this.addressComponents,
    required this.formattedAddress,
    required this.geometry,
    required this.placeId,
    required this.reference,
    required this.businessStatus,
    required this.formattedPhoneNumber,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconMaskBaseUri,
    required this.internationalPhoneNumber,
    required this.name,
    required this.openingHours,
    required this.plusCode,
    required this.rating,
    required this.reviews,
    required this.types,
    required this.layer,
    required this.url,
    required this.userRatingsTotal,
    required this.utcOffset,
    required this.vicinity,
    required this.website,
    required this.priceLevel,
    required this.photos,
    required this.adrAddress,
    this.amenitiesAvailable = const [],
    this.wheelchairAccessibility = false,
    this.parkingAvailable = false,
    this.isLandmark = false,
    this.landmarkType = '',
    this.paymentMode = '',
    this.popularItems = const [],
    this.languageSpoken,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      addressComponents: ((json['address_components'] as List?) ?? const [])
          .map((e) => AddressComponent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      formattedAddress: json['formatted_address']?.toString() ?? '',
      geometry: Geometry.fromJson(
        Map<String, dynamic>.from(json['geometry'] as Map? ?? const {}),
      ),
      placeId: json['place_id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      businessStatus: json['business_status']?.toString() ?? '',
      formattedPhoneNumber: json['formatted_phone_number']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      iconBackgroundColor: json['icon_background_color']?.toString() ?? '',
      iconMaskBaseUri: json['icon_mask_base_uri']?.toString() ?? '',
      internationalPhoneNumber:
          json['international_phone_number']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      openingHours: json['opening_hours'] is Map
          ? OpeningHours.fromJson(
              Map<String, dynamic>.from(json['opening_hours'] as Map),
            )
          : OpeningHours(openNow: false, periods: const [], weekdayText: const []),
      plusCode: json['plus_code'] is Map
          ? PlusCode.fromJson(Map<String, dynamic>.from(json['plus_code'] as Map))
          : PlusCode(compoundCode: '', globalCode: ''),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: ((json['reviews'] as List?) ?? const [])
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      types: List<String>.from(json['types'] ?? const []),
      layer: List<String>.from(json['layer'] ?? const []),
      url: json['url']?.toString() ?? '',
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt() ?? 0,
      utcOffset: (json['utc_offset'] as num?)?.toInt() ?? 0,
      vicinity: json['vicinity']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      priceLevel: json['price_level']?.toString() ?? '',
      photos: json['photos'] ?? [],
      adrAddress: json['adr_address']?.toString() ?? '',
      amenitiesAvailable: json['amenities_available'] as List? ?? const [],
      wheelchairAccessibility: json['wheelchair_accessibility'] == true ||
          json['wheelchair_accessibility']?.toString() == 'yes',
      parkingAvailable: json['parking_available'] == true ||
          json['parking_available']?.toString() == 'yes',
      isLandmark: json['is_landmark'] == true,
      landmarkType: json['landmark_type']?.toString() ?? '',
      paymentMode: json['payment_mode']?.toString() ?? '',
      popularItems: json['popular_items'] as List? ?? const [],
      languageSpoken: json['language_spoken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_components': addressComponents.map((e) => e.toJson()).toList(),
      'formatted_address': formattedAddress,
      'geometry': geometry.toJson(),
      'place_id': placeId,
      'reference': reference,
      'business_status': businessStatus,
      'formatted_phone_number': formattedPhoneNumber,
      'icon': icon,
      'icon_background_color': iconBackgroundColor,
      'icon_mask_base_uri': iconMaskBaseUri,
      'international_phone_number': internationalPhoneNumber,
      'name': name,
      'opening_hours': openingHours.toJson(),
      'plus_code': plusCode.toJson(),
      'rating': rating,
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'types': types,
      'layer': layer,
      'url': url,
      'user_ratings_total': userRatingsTotal,
      'utc_offset': utcOffset,
      'vicinity': vicinity,
      'website': website,
      'price_level': priceLevel,
      'photos': photos,
      'adr_address': adrAddress,
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
    return 'PlaceDetails{name: $name, formattedAddress: $formattedAddress, rating: $rating}';
  }
}

class OpeningHours {
  final bool openNow;
  final List<Period> periods;
  final List<String> weekdayText;

  OpeningHours(
      {required this.openNow,
      required this.periods,
      required this.weekdayText});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'] == true,
      periods: ((json['periods'] as List?) ?? const [])
          .map((e) => Period.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weekdayText: List<String>.from(json['weekday_text'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open_now': openNow,
      'periods': periods.map((e) => e.toJson()).toList(),
      'weekday_text': weekdayText,
    };
  }
}

class Period {
  final Time close;
  final Time open;

  Period({required this.close, required this.open});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      close: Time.fromJson(
        Map<String, dynamic>.from(json['close'] as Map? ?? const {}),
      ),
      open: Time.fromJson(
        Map<String, dynamic>.from(json['open'] as Map? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'close': close.toJson(),
      'open': open.toJson(),
    };
  }
}

class Time {
  final int day;
  final String time;

  Time({required this.day, required this.time});

  factory Time.fromJson(Map<String, dynamic> json) {
    return Time(
      day: (json['day'] as num?)?.toInt() ?? 0,
      time: json['time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'time': time,
    };
  }
}

class Review {
  final String authorName;
  final String authorUrl;
  final String language;
  final String profilePhotoUrl;
  final int rating;
  final String relativeTimeDescription;
  final String text;
  final int time;

  Review({
    required this.authorName,
    required this.authorUrl,
    required this.language,
    required this.profilePhotoUrl,
    required this.rating,
    required this.relativeTimeDescription,
    required this.text,
    required this.time,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName: json['author_name'],
      authorUrl: json['author_url'],
      language: json['language'],
      profilePhotoUrl: json['profile_photo_url'],
      rating: json['rating'],
      relativeTimeDescription: json['relative_time_description'],
      text: json['text'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_name': authorName,
      'author_url': authorUrl,
      'language': language,
      'profile_photo_url': profilePhotoUrl,
      'rating': rating,
      'relative_time_description': relativeTimeDescription,
      'text': text,
      'time': time,
    };
  }
}
