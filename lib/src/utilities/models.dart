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
  String locationType;

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
  LatLng southwest;
  LatLng northeast;

  Viewport({
    required this.southwest,
    required this.northeast,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      southwest: LatLng.fromJson(json['southwest']),
      northeast: LatLng.fromJson(json['northeast']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'southwest': southwest.toJson(),
      'northeast': northeast.toJson(),
    };
  }
}

class LatLng {
  double lng;
  double lat;

  LatLng({
    required this.lng,
    required this.lat,
  });

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
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
