// lib/screens/route_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/hazards.dart';
import '../data/routes.dart';
import '../models/poi.dart';
import '../models/travel_route.dart';
import '../state/offline.dart';
import '../state/road_marks.dart';
import '../state/trip.dart';
import '../widgets/premium_gate.dart';
import '../widgets/route_card.dart';
import '../widgets/route_map.dart';

/// Маршрутын дэлгэрэнгүй: газрын зураг, үзүүлэлт, өдөр бүрийн төлөвлөгөө,
/// зардал, «Аялалд нэмэх».
class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key, required this.route});

  final TravelRoute route;

  Future<void> _addToTrip(BuildContext context) async {
    final current = trip.route;
    if (route.premium && current?.id != route.id) {
      final ok = await requirePremium(
        context,
        '«${route.name}» нь Premium маршрут. Premium захиалгаар бүх '
        'маршрут, хязгааргүй офлайн газрын зураг, замын тэмдэглэгээ нээгдэнэ.',
      );
      if (!ok || !context.mounted) return;
    }
    if (current != null && current.id != route.id) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Аяллаа солих уу?'),
          content: Text(
            '«${current.name}» аяллын явц, жагсаалт устаж, '
            '«${route.name}» шинээр эхэлнэ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Болих'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Солих'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (current?.id != route.id) trip.start(route.id);
    if (context.mounted) context.push('/trip');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(route.name),
          actions: [
            if (route.premium) const Center(child: PremiumBadge(compact: true)),
            RouteFavoriteButton(routeId: route.id),
            const SizedBox(width: 8),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ойролцоо зардал', style: text.bodySmall),
                    Text(
                      '≈ ${formatCost(route.costPerPerson)}',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('1 хүн', style: text.bodySmall),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListenableBuilder(
                    listenable: trip,
                    builder: (context, _) => FilledButton.icon(
                      onPressed: () => _addToTrip(context),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        trip.route?.id == route.id
                            ? 'Аяллаа үргэлжлүүлэх'
                            : 'Аялалд нэмэх',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView(
          children: [
            SizedBox(
              height: 300,
              child: ValueListenableBuilder(
                valueListenable: roadMarks,
                builder: (context, _, _) => RouteMap(
                  route: route,
                  marks: marksOf(route.id),
                  // Маршрутын дагуух шатахуун түгээх станцууд
                  pois: poisOf(
                    route.id,
                  ).where((p) => p.type == PoiType.fuel).toList(),
                  onPoiTap: (_) => context.push('/route/${route.id}/roadside'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final tag in route.tags)
                        Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.rating.toStringAsFixed(1)} · '
                        '${route.travelers} аялагч явсан',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Stat(Icons.calendar_today, '${route.dayCount}', 'өдөр'),
                      _Stat(Icons.route, formatKm(route.totalKm), 'км'),
                      _Stat(
                        Icons.place_outlined,
                        '${route.stopCount}',
                        'зогсоол',
                      ),
                      _Stat(Icons.wb_sunny_outlined, route.months, 'сар'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/route/${route.id}/roadside'),
                          icon: const Icon(Icons.local_gas_station_outlined),
                          label: const Text('Зам дээрх цэгүүд'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<Set<String>>(
                          valueListenable: offlineRegionIds,
                          builder: (context, ids, _) => OutlinedButton.icon(
                            onPressed: () => context.push('/offline'),
                            icon: Icon(
                              ids.contains(route.region)
                                  ? Icons.offline_pin
                                  : Icons.download_outlined,
                            ),
                            label: Text(
                              ids.contains(route.region)
                                  ? 'Офлайнд бэлэн'
                                  : 'Офлайнд татах',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: roadMarks,
                      builder: (context, _, _) {
                        final count = marksOf(route.id).length;
                        return FilledButton.tonalIcon(
                          onPressed: () =>
                              context.push('/route/${route.id}/marks'),
                          icon: const Icon(Icons.edit_location_alt_outlined),
                          label: Text(
                            count == 0
                                ? 'Замын тэмдэглэгээ хийх'
                                : 'Замын тэмдэглэгээ ($count)',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Өдрөөр'),
                      Tab(text: 'Зам'),
                      Tab(text: 'Зардал'),
                    ],
                  ),
                ],
              ),
            ),
            // ListView дотор TabBarView өндөр мэдэхгүй тул сонгосон табыг
            // шууд зурна
            Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: switch (controller.index) {
                      0 => _DayList(route: route),
                      1 => _RoadConditions(route: route),
                      _ => _CostTable(route: route, colors: colors),
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

String formatHours(double h) =>
    h == h.roundToDouble() ? '${h.round()}' : h.toStringAsFixed(1);

class _DayList extends StatelessWidget {
  const _DayList({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        for (var i = 0; i < route.days.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: Text('${i + 1}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}-р өдөр',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          Text(
                            route.days[i].title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${route.days[i].km} км · '
                            '~${formatHours(route.days[i].hours)} цаг',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(route.days[i].highlight),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.hotel, size: 16),
                                label: Text(route.days[i].stay),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (route.days[i].fuel != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.local_gas_station,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Шатахуун: ${route.days[i].fuel}',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Нэг хүний ойролцоо зардлын задаргаа (жишээ хувь хэмжээгээр).
class _CostTable extends StatelessWidget {
  const _CostTable({required this.route, required this.colors});

  final TravelRoute route;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final total = route.costPerPerson;
    final rows = <(IconData, String, double)>[
      (Icons.local_gas_station, 'Шатахуун', 0.35),
      (Icons.hotel, 'Байр, хоноглолт', 0.30),
      (Icons.restaurant, 'Хоол хүнс', 0.25),
      (Icons.confirmation_number_outlined, 'Тасалбар, бусад', 0.10),
    ];
    return Column(
      children: [
        for (final (icon, label, share) in rows)
          ListTile(
            dense: true,
            leading: Icon(icon, color: colors.primary),
            title: Text(label),
            subtitle: LinearProgressIndicator(value: share),
            trailing: Text(formatCost((total * share).round())),
          ),
        const Divider(),
        ListTile(
          title: const Text('Нийт (1 хүн)'),
          trailing: Text(
            '≈ ${formatCost(total)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          'Зардал нь ойролцоо тооцоо бөгөөд улирал, шатахууны үнээс хамаарна.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// «Замын нөхцөл»: зогсоол хоорондын хэсэг бүр засмал, шороон эсвэл
/// бартаат эсэх. Газрын зураг дээр ижил өнгөөр зурагдана.
class _RoadConditions extends StatelessWidget {
  const _RoadConditions({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final segments = route.segments;
    final rough = route.roughCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rough > 0
                ? colors.errorContainer
                : colors.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                rough > 0 ? Icons.terrain : Icons.check_circle_outline,
                color: rough > 0
                    ? colors.onErrorContainer
                    : colors.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rough > 0
                      ? '$rough хэсэг бартаат замтай. Жийп унаа, нөөц дугуй, '
                            'хамтдаа явах машинтай байхыг зөвлөнө.'
                      : 'Бартаат зам байхгүй — суудлын машинаар явж болно.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: rough > 0
                        ? colors.onErrorContainer
                        : colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final seg in segments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: seg.type.color,
              child: Icon(
                switch (seg.type) {
                  RoadType.paved => Icons.add_road,
                  RoadType.dirt => Icons.landscape_outlined,
                  RoadType.rough => Icons.terrain,
                },
                size: 18,
                color: Colors.white,
              ),
            ),
            title: Text(seg.title),
            subtitle: Text(seg.type.description),
            trailing: Text(
              seg.type.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: seg.type.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (hazardsOf(route.id).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Анхаарах цэгүүд',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final h in hazardsOf(route.id))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: h.type.color,
                child: Icon(h.type.icon, size: 18, color: Colors.white),
              ),
              title: Text(h.title),
              subtitle: Text(h.note),
              onTap: () => showHazardSheet(context, h),
            ),
        ],
        const SizedBox(height: 4),
        Text(
          'Замын төрөл нь ойролцоо мэдээлэл. Замдаа тааралдсан бартаат '
          'хэсгээ «Замын тэмдэглэгээ»-д тэмдэглэж аваарай.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
