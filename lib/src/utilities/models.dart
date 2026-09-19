export 'near_by_place_details.dart';
export 'auto_complete_results.dart';

/// Geocoded place returned by Places / Geocode APIs.
class Address {
  /// Single-line display address.
  String formattedAddress;

  /// Place-type tags (`street_address`, `establishment`, …).
  List<String> types;

  /// Human-readable place name.
  String name;

  /// Coordinate and viewport.
  Geometry geometry;

  /// Structured address parts.
  List<AddressComponent> addressComponents;

  /// Open Location Code for this place.
  PlusCode plusCode;

  /// Ola Maps place id.
  String placeId;

  /// Map-data layers this result belongs to.
  List<String> layer;

  /// Creates an address model.
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

  /// Parses an address from a Places / Geocode JSON object.
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

  /// Serializes this address to the Places JSON shape.
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

/// Coordinate plus optional viewport for a place.
class Geometry {
  /// Bounding box suggested for camera fit.
  Viewport viewport;

  /// Pin coordinate.
  Location location;

  /// Geocoder location type (`ROOFTOP`, `APPROXIMATE`, …).
  String? locationType;

  /// Creates a geometry object.
  Geometry({
    required this.viewport,
    required this.location,
    required this.locationType,
  });

  /// Parses `{viewport, location, location_type}`.
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

  /// Serializes viewport, location, and type.
  Map<String, dynamic> toJson() {
    return {
      'viewport': viewport.toJson(),
      'location': location.toJson(),
      'location_type': locationType,
    };
  }
}

/// Southwest / northeast pair describing a map bounds.
class Viewport {
  /// Lower-left corner.
  Location southwest;

  /// Upper-right corner.
  Location northeast;

  /// Creates a viewport from two corners.
  Viewport({
    required this.southwest,
    required this.northeast,
  });

  /// Parses `{southwest, northeast}`.
  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      southwest: Location.fromJson(json['southwest']),
      northeast: Location.fromJson(json['northeast']),
    );
  }

  /// Serializes both corners.
  Map<String, dynamic> toJson() {
    return {
      'southwest': southwest.toJson(),
      'northeast': northeast.toJson(),
    };
  }
}

/// Latitude / longitude used by Places and Routing HTTP APIs.
class Location {
  /// Degrees east of the prime meridian.
  double lng;

  /// Degrees north of the equator.
  double lat;

  /// Creates a WGS84 point. Note argument order is `[lng], [lat]`.
  Location({
    required this.lng,
    required this.lat,
  });

  /// Parses `lat`/`lng` or `latitude`/`longitude`.
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

  /// True when this is not the `(0, 0)` fallback used for missing geometry.
  bool get hasCoordinates => lat != 0 || lng != 0;

  /// Serializes `{lat, lng}`.
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

/// One structured part of an [Address] (city, postal code, …).
class AddressComponent {
  /// Component types (`locality`, `postal_code`, …).
  List<String> types;

  /// Abbreviated label.
  String shortName;

  /// Full label.
  String longName;

  /// Creates an address component.
  AddressComponent({
    required this.types,
    required this.shortName,
    required this.longName,
  });

  /// Parses `{types, short_name, long_name}`.
  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      types: List<String>.from(json['types'] ?? const []),
      shortName: json['short_name']?.toString() ?? '',
      longName: json['long_name']?.toString() ?? '',
    );
  }

  /// Serializes this component.
  Map<String, dynamic> toJson() {
    return {
      'types': types,
      'short_name': shortName,
      'long_name': longName,
    };
  }
}

/// Open Location Code (Plus Code) for a place.
class PlusCode {
  /// Area-relative code.
  String compoundCode;

  /// Global Plus Code.
  String globalCode;

  /// Creates a Plus Code pair.
  PlusCode({
    required this.compoundCode,
    required this.globalCode,
  });

  /// Parses `{compound_code, global_code}`.
  factory PlusCode.fromJson(Map<String, dynamic> json) {
    return PlusCode(
      compoundCode: json['compound_code']?.toString() ?? '',
      globalCode: json['global_code']?.toString() ?? '',
    );
  }

  /// Serializes both codes.
  Map<String, dynamic> toJson() {
    return {
      'compound_code': compoundCode,
      'global_code': globalCode,
    };
  }
}

/// One row from Places text search.
class TextSearchPrediction {
  /// Formatted address line.
  final String formattedAddress;

  /// Result coordinate.
  final Location geometry;

  /// Ola Maps place id.
  final String placeId;

  /// Place name.
  final String name;

  /// Place-type tags.
  final List<String> types;

  /// Creates a text-search row.
  TextSearchPrediction({
    required this.formattedAddress,
    required this.geometry,
    required this.placeId,
    required this.name,
    required this.types,
  });

  /// Parses a text-search prediction JSON object.
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

  /// Serializes this prediction.
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

/// Full place record from Place Details.
class PlaceDetails {
  /// Structured address parts.
  final List<AddressComponent> addressComponents;

  /// Single-line display address.
  final String formattedAddress;

  /// Coordinate and viewport.
  final Geometry geometry;

  /// Ola Maps place id.
  final String placeId;

  /// Alternate place reference token.
  final String reference;

  /// Business open/closed status.
  final String businessStatus;

  /// Local formatted phone number.
  final String formattedPhoneNumber;

  /// Icon URL.
  final String icon;

  /// Icon background color hex.
  final String iconBackgroundColor;

  /// Icon mask URI.
  final String iconMaskBaseUri;

  /// International formatted phone number.
  final String internationalPhoneNumber;

  /// Place name.
  final String name;

  /// Opening hours, if published.
  final OpeningHours openingHours;

  /// Open Location Code.
  final PlusCode plusCode;

  /// Average user rating.
  final double rating;

  /// User reviews.
  final List<Review> reviews;

  /// Place-type tags.
  final List<String> types;

  /// Map-data layers.
  final List<String> layer;

  /// Maps URL for this place.
  final String url;

  /// Number of user ratings.
  final int userRatingsTotal;

  /// UTC offset in minutes.
  final int utcOffset;

  /// Neighborhood / vicinity label.
  final String vicinity;

  /// Website URL.
  final String website;

  /// Price-level label.
  final String priceLevel;

  /// Photo metadata list.
  final List<dynamic> photos;

  /// Address in microformat (`adr`).
  final String adrAddress;

  /// Amenities advertised by the place.
  final List<dynamic> amenitiesAvailable;

  /// Wheelchair access flag.
  final bool wheelchairAccessibility;

  /// Parking flag.
  final bool parkingAvailable;

  /// Whether this is classified as a landmark.
  final bool isLandmark;

  /// Landmark category.
  final String landmarkType;

  /// Accepted payment modes.
  final String paymentMode;

  /// Popular menu or catalog items.
  final List<dynamic> popularItems;

  /// Languages spoken at the venue.
  final dynamic languageSpoken;

  /// Creates a place-details record.
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

  /// Parses a Place Details JSON object.
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

  /// Serializes this place to the Place Details JSON shape.
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

/// Published hours for a [PlaceDetails] result.
class OpeningHours {
  /// Whether the place is open at request time.
  final bool openNow;

  /// Open/close windows by weekday.
  final List<Period> periods;

  /// Localized weekday strings.
  final List<String> weekdayText;

  /// Creates opening-hours data.
  OpeningHours(
      {required this.openNow,
      required this.periods,
      required this.weekdayText});

  /// Parses `{open_now, periods, weekday_text}`.
  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'] == true,
      periods: ((json['periods'] as List?) ?? const [])
          .map((e) => Period.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weekdayText: List<String>.from(json['weekday_text'] ?? const []),
    );
  }

  /// Serializes opening hours.
  Map<String, dynamic> toJson() {
    return {
      'open_now': openNow,
      'periods': periods.map((e) => e.toJson()).toList(),
      'weekday_text': weekdayText,
    };
  }
}

/// One open/close window inside [OpeningHours].
class Period {
  /// Closing clock time.
  final Time close;

  /// Opening clock time.
  final Time open;

  /// Creates an open/close pair.
  Period({required this.close, required this.open});

  /// Parses `{open, close}`.
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

  /// Serializes this period.
  Map<String, dynamic> toJson() {
    return {
      'close': close.toJson(),
      'open': open.toJson(),
    };
  }
}

/// Weekday plus `HHmm` clock time.
class Time {
  /// Day of week (0 = Sunday).
  final int day;

  /// Local time as `HHmm`.
  final String time;

  /// Creates a weekday clock time.
  Time({required this.day, required this.time});

  /// Parses `{day, time}`.
  factory Time.fromJson(Map<String, dynamic> json) {
    return Time(
      day: (json['day'] as num?)?.toInt() ?? 0,
      time: json['time']?.toString() ?? '',
    );
  }

  /// Serializes day and clock time.
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'time': time,
    };
  }
}

/// User review attached to [PlaceDetails].
class Review {
  /// Display name of the author.
  final String authorName;

  /// Profile URL.
  final String authorUrl;

  /// Review language code.
  final String language;

  /// Avatar URL.
  final String profilePhotoUrl;

  /// Star rating.
  final int rating;

  /// Relative time label (`2 months ago`).
  final String relativeTimeDescription;

  /// Review body.
  final String text;

  /// Unix timestamp.
  final int time;

  /// Creates a review.
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

  /// Parses a review JSON object.
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

  /// Serializes this review.
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
