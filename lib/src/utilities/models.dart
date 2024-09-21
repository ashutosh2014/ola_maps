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
    return Address(
      formattedAddress: json['formatted_address'],
      types: List<String>.from(json['types']),
      name: json['name'],
      geometry: Geometry.fromJson(json['geometry']),
      addressComponents: (json['address_components'] as List)
          .map((i) => AddressComponent.fromJson(i))
          .toList(),
      plusCode: PlusCode.fromJson(json['plus_code']),
      placeId: json['place_id'],
      layer: List<String>.from(json['layer']),
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
    return Geometry(
      viewport: Viewport.fromJson(json['viewport']),
      location: Location.fromJson(json['location']),
      locationType: json['location_type'],
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
      lng: json['lng'],
      lat: json['lat'],
    );
  }

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
      types: List<String>.from(json['types']),
      shortName: json['short_name'],
      longName: json['long_name'],
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
      compoundCode: json['compound_code'],
      globalCode: json['global_code'],
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
    return TextSearchPrediction(
      formattedAddress: json['formatted_address'],
      geometry: Location.fromJson(json['geometry']['location']),
      placeId: json['place_id'],
      name: json['name'],
      types: List<String>.from(json['types']),
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
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      addressComponents: (json['address_components'] as List)
          .map((e) => AddressComponent.fromJson(e))
          .toList(),
      formattedAddress: json['formatted_address'],
      geometry: Geometry.fromJson(json['geometry']),
      placeId: json['place_id'],
      reference: json['reference'],
      businessStatus: json['business_status'],
      formattedPhoneNumber: json['formatted_phone_number'],
      icon: json['icon'],
      iconBackgroundColor: json['icon_background_color'],
      iconMaskBaseUri: json['icon_mask_base_uri'],
      internationalPhoneNumber: json['international_phone_number'],
      name: json['name'],
      openingHours: OpeningHours.fromJson(json['opening_hours']),
      plusCode: PlusCode.fromJson(json['plus_code']),
      rating: json['rating'].toDouble(),
      reviews:
          (json['reviews'] as List).map((e) => Review.fromJson(e)).toList(),
      types: List<String>.from(json['types']),
      layer: List<String>.from(json['layer']),
      url: json['url'],
      userRatingsTotal: json['user_ratings_total'],
      utcOffset: json['utc_offset'],
      vicinity: json['vicinity'],
      website: json['website'],
      priceLevel: json['price_level'],
      photos: json['photos'] ?? [],
      adrAddress: json['adr_address'],
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
      openNow: json['open_now'],
      periods:
          (json['periods'] as List).map((e) => Period.fromJson(e)).toList(),
      weekdayText: List<String>.from(json['weekday_text']),
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
      close: Time.fromJson(json['close']),
      open: Time.fromJson(json['open']),
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
      day: json['day'],
      time: json['time'],
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
