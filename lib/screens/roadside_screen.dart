// lib/screens/roadside_screen.dart
import 'package:flutter/material.dart';

import '../data/routes.dart';
import '../models/poi.dart';
import '../models/travel_route.dart';
import '../state/trip.dart';
import '../utils/geo.dart';
import '../widgets/route_map.dart';

/// «Зам дээрх цэгүүд»: маршрутын дагуух шатахуун, засвар, эмнэлэг, дэлгүүр.
/// Дээр нь дараагийн шатахуун хүртэлх зайн сэрэмжлүүлэг харуулна.
class RoadsideScreen extends StatefulWidget {
  const RoadsideScreen({super.key, required this.route});

  final TravelRoute route;

  @override
  State<RoadsideScreen> createState() => _RoadsideScreenState();
}

class _RoadsideScreenState extends State<RoadsideScreen> {
  PoiType? _type; // null = бүгд

  void _showPoi(Poi p) {
    showModalBottomSheet<void>(
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
                backgroundColor: p.type.color,
                child: Icon(p.type.icon, color: Colors.white),
              ),
              title: Text(p.name),
              subtitle: Text('${p.type.label} · ${p.place}'),
            ),
            Text('Маршрутын эхлэлээс: ${p.km} км'),
            Text('Координат: ${formatCoordinates(p.latitude, p.longitude)}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final route = widget.route;
    final all = poisOf(route.id);
    final items = _type == null
        ? all
        : all.where((p) => p.type == _type).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Зам дээрх цэгүүд')),
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: RouteMap(route: route, pois: items, onPoiTap: _showPoi),
          ),
          // Аялал идэвхтэй бол явцаас, үгүй бол эхлэлээс тооцно
          ListenableBuilder(
            listenable: trip,
            builder: (context, _) {
              final onTrip = trip.route?.id == route.id;
              final at = onTrip
                  ? route.kmAfterDays(trip.currentDay ?? route.dayCount)
                  : 0;
              final fuel = nextFuel(route.id, at);
              if (fuel == null) return const SizedBox.shrink();
              final away = fuel.km - at;
              final far = away >= 200;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: far
                      ? colors.errorContainer
                      : colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      far ? Icons.warning_amber : Icons.local_gas_station,
                      color: far
                          ? colors.onErrorContainer
                          : colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Дараагийн шатахуун $away км дараа — ${fuel.place}'
                        '${far ? '. Саваа дүүргээрэй!' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: far
                              ? colors.onErrorContainer
                              : colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Бүгд (${all.length})'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                for (final t in PoiType.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 16),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Энэ төрлийн цэг алга.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.type.color,
                          child: Icon(
                            p.type.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text('${p.type.label} · ${p.place}'),
                        trailing: Text(
                          '${p.km} км',
                          style: theme.textTheme.labelLarge,
                        ),
                        onTap: () => _showPoi(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
