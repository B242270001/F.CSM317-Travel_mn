// lib/widgets/route_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../data/hazards.dart';
import '../data/places.dart';
import '../data/route_shapes.dart';
import '../models/poi.dart';
import '../models/road_mark.dart';
import '../models/travel_route.dart';

/// Маршрутын шугам, дугаарласан зогсоол, (сонголтоор) үйлчилгээний цэгүүд
/// болон хэрэглэгчийн замын тэмдэглэгээг OpenStreetMap дээр харуулна.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.route,
    this.pois = const [],
    this.onPoiTap,
    this.marks = const [],
    this.onMarkTap,
    this.onLongPress,
    this.interactive = true,
    this.showLegend = true,
    this.showHazards = true,
  });

  /// Апп-д урьдчилан оруулсан бартаат зам, гол гатлах цэгийг харуулах эсэх.
  final bool showHazards;

  /// Замын төрлийн (засмал / шороон / бартаат) тайлбарыг харуулах эсэх.
  final bool showLegend;

  final TravelRoute route;
  final List<Poi> pois;
  final ValueChanged<Poi>? onPoiTap;

  /// Хэрэглэгчийн замын тэмдэглэгээ.
  final List<RoadMark> marks;
  final ValueChanged<RoadMark>? onMarkTap;

  /// Газрын зураг дээр удаан дарахад (шинэ тэмдэглэгээ нэмэх).
  final ValueChanged<LatLng>? onLongPress;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final segments = route.segments;
    final shapes = segmentPoints(route);
    final points = [for (final seg in shapes) ...seg];
    // Шороон → засмал → бартаат дарааллаар зурна: давхцсан хурдны зам
    // засмалаар, бартаат хэсэг хамгийн дээр харагдана
    const rank = {RoadType.dirt: 0, RoadType.paved: 1, RoadType.rough: 2};
    final drawOrder = [for (var i = 0; i < segments.length; i++) i]
      ..sort(
        (a, b) => rank[segments[a].type]!.compareTo(rank[segments[b].type]!),
      );
    // Эхлэл, төгсгөлийн УБ давхардахгүйн тулд сүүлийнхийг хасна
    final stops = route.stops.sublist(0, route.stops.length - 1);

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          // доод талд эх сурвалжийн бичигт зай үлдээнэ
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 60),
        ),
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onLongPress: onLongPress == null
            ? null
            : (_, point) => onLongPress!(point),
        // Вэб, компьютер дээр баруун товчоор дарж мөн нэмнэ
        onSecondaryTap: onLongPress == null
            ? null
            : (_, point) => onLongPress!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: appPackageName,
          maxNativeZoom: 19,
        ),
        // Замын хэсэг бүрийг төрлөөр нь өнгөлнө; бартаатыг тасархай шугамаар,
        // бусад шугамд дарагдахгүйн тулд хамгийн сүүлд зурна
        PolylineLayer(
          polylines: [
            for (final i in drawOrder)
              Polyline(
                points: shapes[i],
                strokeWidth: 5,
                color: segments[i].type.color,
                borderStrokeWidth: 1.5,
                borderColor: Colors.white,
                pattern: segments[i].type == RoadType.rough
                    ? StrokePattern.dashed(segments: const [12, 7])
                    : const StrokePattern.solid(),
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < stops.length; i++)
              _stopMarker(context, colors, stops[i], i),
            // Үйлчилгээний цэгийг зогсоолын ДЭЭР зүү хэлбэрээр зурна —
            // зогсоолтой ижил газар байсан ч (Мандалговь гэх мэт) далдлагдахгүй
            for (final p in pois)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 30,
                height: 38,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onPoiTap == null ? null : () => onPoiTap!(p),
                  child: Tooltip(
                    message: '${p.type.label} · ${p.place}',
                    child: _Pin(color: p.type.color, icon: p.type.icon),
                  ),
                ),
              ),
            // Апп-ын анхааруулга (бартаат зам, гол гатлах) — зам дээр
            if (showHazards)
              for (final h in hazardsOf(route.id))
                Marker(
                  point: h.point,
                  width: 30,
                  height: 38,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => showHazardSheet(context, h),
                    child: Tooltip(
                      message: h.title,
                      child: _MarkPin(type: h.type),
                    ),
                  ),
                ),
            // Хэрэглэгчийн тэмдэглэгээ — зүү хэлбэртэй, бусдаас дээр зурна
            for (final m in marks)
              Marker(
                point: LatLng(m.latitude, m.longitude),
                width: 30,
                height: 38,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onMarkTap == null ? null : () => onMarkTap!(m),
                  child: Tooltip(
                    message: m.note.isEmpty
                        ? m.type.label
                        : '${m.type.label}: ${m.note}',
                    child: _MarkPin(type: m.type),
                  ),
                ),
              ),
          ],
        ),
        if (showLegend) _RoadLegend(route: route),
        // OSM-ийн нөхцөл: эх сурвалжийг заавал харуулна
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  /// Зогсоолын дугаарласан тэмдэг. Зогсоол нь апп-ын газар (Цагаан суварга,
  /// Ёлын ам ...) бол өнгөөр дүүргэж, дарахад тухайн газрын дэлгэрэнгүй нээнэ.
  Marker _stopMarker(
    BuildContext context,
    ColorScheme colors,
    RouteStop stop,
    int index,
  ) {
    final isStart = index == 0;
    final place = isStart ? null : placeNear(stop.latitude, stop.longitude);
    final background = isStart
        ? colors.inverseSurface
        : place != null
        ? colors.primary
        : colors.surface;
    final foreground = isStart
        ? colors.onInverseSurface
        : place != null
        ? colors.onPrimary
        : colors.primary;
    final badge = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary, width: 2),
      ),
      child: Text(
        isStart ? 'УБ' : '$index',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
    return Marker(
      point: LatLng(stop.latitude, stop.longitude),
      width: 28,
      height: 28,
      child: Tooltip(
        message: place == null ? stop.name : '${stop.name} · дэлгэрэнгүй',
        child: place == null
            ? badge
            : MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.push('/place/${place.id}'),
                  child: badge,
                ),
              ),
      ),
    );
  }
}

/// Анхааруулгын дэлгэрэнгүй.
Future<void> showHazardSheet(BuildContext context, RoadHazard h) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: h.type.color,
              child: Icon(h.type.icon, color: Colors.white),
            ),
            title: Text(h.title),
            subtitle: Text(h.type.label),
          ),
          Text(h.note, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}

/// Хэсэг бүрийн замын хэлбэр: хадгалсан бодит замын цэгүүд, байхгүй бол
/// хоёр зогсоолыг шулуунаар холбоно.
List<List<LatLng>> segmentPoints(TravelRoute route) {
  final saved = routeShapes[route.id];
  final segments = route.segments;
  return [
    for (var i = 0; i < segments.length; i++)
      if (saved != null && i < saved.length && saved[i].length >= 4)
        [
          for (var j = 0; j + 1 < saved[i].length; j += 2)
            LatLng(saved[i][j], saved[i][j + 1]),
        ]
      else
        [
          LatLng(segments[i].from.latitude, segments[i].from.longitude),
          LatLng(segments[i].to.latitude, segments[i].to.longitude),
        ],
  ];
}

/// Газрын зургийн буланд замын төрлийн тайлбар (маршрутад байгааг л).
class _RoadLegend extends StatelessWidget {
  const _RoadLegend({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context) {
    final types = {for (final s in route.segments) s.type};
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final t in RoadType.values)
              if (types.contains(t))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RoadTypeSwatch(type: t),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Замын төрлийн жижиг шугамын дээж (бартаат бол тасархай).
class RoadTypeSwatch extends StatelessWidget {
  const RoadTypeSwatch({super.key, required this.type, this.width = 22});

  final RoadType type;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (type != RoadType.rough) {
      return Container(
        width: width,
        height: 4,
        decoration: BoxDecoration(
          color: type.color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return SizedBox(
      width: width,
      height: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 3; i++)
            Container(width: width / 4, height: 4, color: type.color),
        ],
      ),
    );
  }
}

/// Тэмдэглэгээний зүү.
class _MarkPin extends StatelessWidget {
  const _MarkPin({required this.type});

  final RoadMarkType type;

  @override
  Widget build(BuildContext context) =>
      _Pin(color: type.color, icon: type.icon);
}

/// Зүү: өнгөт дугуй + доош чиглэсэн сум (үзүүр нь яг цэг дээр).
class _Pin extends StatelessWidget {
  const _Pin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        Icon(Icons.arrow_drop_down, size: 12, color: color),
      ],
    );
  }
}
