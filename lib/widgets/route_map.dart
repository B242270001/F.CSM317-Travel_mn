// lib/widgets/route_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/poi.dart';
import '../models/travel_route.dart';

/// Маршрутын шугам, дугаарласан зогсоол, (сонголтоор) үйлчилгээний цэгүүдийг
/// OpenStreetMap дээр харуулна.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.route,
    this.pois = const [],
    this.onPoiTap,
    this.interactive = true,
  });

  final TravelRoute route;
  final List<Poi> pois;
  final ValueChanged<Poi>? onPoiTap;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final points = [
      for (final s in route.stops) LatLng(s.latitude, s.longitude),
    ];
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
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: appPackageName,
          maxNativeZoom: 19,
        ),
        PolylineLayer(
          polylines: [
            Polyline(points: points, strokeWidth: 4, color: colors.primary),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final p in pois)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 30,
                height: 30,
                child: GestureDetector(
                  onTap: onPoiTap == null ? null : () => onPoiTap!(p),
                  child: Tooltip(
                    message: '${p.type.label} · ${p.place}',
                    child: CircleAvatar(
                      backgroundColor: p.type.color,
                      child: Icon(p.type.icon, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < stops.length; i++)
              Marker(
                point: LatLng(stops[i].latitude, stops[i].longitude),
                width: 34,
                height: 34,
                child: Tooltip(
                  message: stops[i].name,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? colors.inverseSurface : colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2.5),
                    ),
                    child: Text(
                      i == 0 ? 'УБ' : '$i',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: i == 0
                            ? colors.onInverseSurface
                            : colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // OSM-ийн нөхцөл: эх сурвалжийг заавал харуулна
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
