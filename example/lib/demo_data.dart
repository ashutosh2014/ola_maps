import 'package:ola_maps/ola_maps.dart';

class DemoPlace {
  final String id;
  final String title;
  final String subtitle;
  final OlaLatLng position;

  const DemoPlace({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.position,
  });
}

/// Sample scene around Magarpatta / Hadapsar, Pune.
class OlaMapsDemoData {
  static const OlaLatLng mapCenter = OlaLatLng(18.5160, 73.9265);
  static const double mapZoom = 13.5;

  static const DemoPlace headquarters = DemoPlace(
    id: 'hq',
    title: 'Ola Campus',
    subtitle: 'Magarpatta, Pune · HQ',
    position: OlaLatLng(18.52145653681468, 73.93178277572254),
  );

  static const DemoPlace pickup = DemoPlace(
    id: 'pickup',
    title: 'Phoenix Mall pickup',
    subtitle: 'Store #PNQ-204 · Ready in 4 min',
    position: OlaLatLng(18.5622, 73.9168),
  );

  static const DemoPlace drop = DemoPlace(
    id: 'drop',
    title: 'Koregaon Park drop',
    subtitle: 'Lane 7, KP · 12.4 km',
    position: OlaLatLng(18.5362, 73.8938),
  );

  static const DemoPlace warehouse = DemoPlace(
    id: 'warehouse',
    title: 'Hadapsar dark store',
    subtitle: 'Open 24×7 · 38 orders queued',
    position: OlaLatLng(18.5086, 73.9259),
  );

  static const List<DemoPlace> places = [
    headquarters,
    pickup,
    drop,
    warehouse,
    DemoPlace(
      id: 'station',
      title: 'Pune Junction',
      subtitle: 'Rail hub · peak traffic',
      position: OlaLatLng(18.5289, 73.8744),
    ),
    DemoPlace(
      id: 'baner',
      title: 'Baner hub',
      subtitle: 'West Pune · 9 riders nearby',
      position: OlaLatLng(18.5590, 73.7868),
    ),
  ];

  /// Approximate Magarpatta township boundary.
  static const List<OlaLatLng> deliveryZone = [
    OlaLatLng(18.5228, 73.9261),
    OlaLatLng(18.5259, 73.9324),
    OlaLatLng(18.5231, 73.9388),
    OlaLatLng(18.5164, 73.9372),
    OlaLatLng(18.5142, 73.9295),
    OlaLatLng(18.5186, 73.9248),
  ];

  /// Stylized road path HQ → Phoenix Mall.
  static const List<OlaLatLng> sampleTrip = [
    OlaLatLng(18.5214, 73.9317),
    OlaLatLng(18.5288, 73.9291),
    OlaLatLng(18.5365, 73.9254),
    OlaLatLng(18.5452, 73.9220),
    OlaLatLng(18.5540, 73.9191),
    OlaLatLng(18.5622, 73.9168),
  ];

  static const OlaLatLng coverageCenter = OlaLatLng(18.5214, 73.9317);
  static const double coverageRadiusMeters = 1800;

  static const List<OlaLatLng> nearbyStores = [
    OlaLatLng(18.5214, 73.9317),
    OlaLatLng(18.5228, 73.9331),
    OlaLatLng(18.5196, 73.9298),
    OlaLatLng(18.5241, 73.9284),
    OlaLatLng(18.5179, 73.9346),
    OlaLatLng(18.5264, 73.9358),
    OlaLatLng(18.5152, 73.9271),
    OlaLatLng(18.5290, 73.9310),
    OlaLatLng(18.5188, 73.9225),
    OlaLatLng(18.5124, 73.9302),
  ];
}
