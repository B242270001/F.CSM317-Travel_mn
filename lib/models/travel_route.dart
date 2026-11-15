// lib/models/travel_route.dart

/// Маршрутын нэг өдөр.
class RouteDay {
  const RouteDay({
    required this.from,
    required this.to,
    required this.km,
    required this.hours,
    required this.highlight,
    required this.stay,
    this.fuel,
  });

  final String from;
  final String to;
  final int km;
  final double hours;
  final String highlight; // тухайн өдрийн үзвэр
  final String stay; // хонох газар
  final String? fuel; // шатахуун авах цэг

  String get title => from == to ? to : '$from → $to';
}

/// Газрын зураг дээрх маршрутын зогсоол.
class RouteStop {
  const RouteStop(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

/// Өдөр бүрээр задалсан бэлэн аяллын маршрут.
class TravelRoute {
  const TravelRoute({
    required this.id,
    required this.name,
    required this.region,
    required this.badge,
    required this.tags,
    required this.vehicle,
    required this.months,
    required this.rating,
    required this.travelers,
    required this.costPerPerson,
    required this.image,
    required this.days,
    required this.stops,
  });

  final String id;
  final String name;
  final String region; // офлайн бүсийн id
  final String badge; // «Хамгийн их сонгогдсон» гэх мэт
  final List<String> tags;
  final String vehicle; // Жийп, Суудлын ...
  final String months; // тохиромжтой сарууд, жишээ нь «6–9»
  final double rating;
  final int travelers;
  final int costPerPerson; // ойролцоо зардал, ₮ (жишээ өгөгдөл)
  final String image;
  final List<RouteDay> days;
  final List<RouteStop> stops; // УБ-аас эхэлж УБ-д дуусна

  int get dayCount => days.length;
  int get totalKm => days.fold(0, (sum, d) => sum + d.km);

  /// УБ-аас бусад зогсоолын тоо.
  int get stopCount => stops.where((s) => s.name != 'УБ').length;

  /// Эхний [dayIndex] өдөр дуусахад туулсан км.
  int kmAfterDays(int dayIndex) =>
      days.take(dayIndex).fold(0, (sum, d) => sum + d.km);

  /// «УБ → Цагаан суварга → ... → УБ»
  String get path => stops.map((s) => s.name).join(' → ');
}
