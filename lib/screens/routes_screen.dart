// lib/screens/routes_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/routes.dart';
import '../models/travel_route.dart';
import '../widgets/route_card.dart';

/// Хоногийн шүүлтүүр.
enum _Length {
  all('Бүгд', 0, 99),
  short('1–3 өдөр', 1, 3),
  medium('4–7 өдөр', 4, 7),
  long('7+ өдөр', 7, 99);

  const _Length(this.label, this.min, this.max);

  final String label;
  final int min;
  final int max;

  bool matches(TravelRoute r) => r.dayCount >= min && r.dayCount <= max;
}

/// «Бэлэн маршрутууд»: өдрөөр задалсан бэлэн маршрутын жагсаалт.
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  _Length _length = _Length.all;

  void _open(TravelRoute route) => context.push('/route/${route.id}');

  /// «Өөрт тохирох маршрут»: хоног, унаагаар тохирохыг санал болгоно.
  Future<void> _recommend() async {
    final route = await showModalBottomSheet<TravelRoute>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _RecommendSheet(),
    );
    if (route != null && mounted) _open(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final items = travelRoutes.where(_length.matches).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Бэлэн маршрутууд',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Төлөвлөх шаардлагагүй — сонгоод л аялаарай',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Material(
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.tertiary],
                  ),
                ),
                child: ListTile(
                  onTap: _recommend,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Icon(Icons.auto_awesome, color: colors.onPrimary),
                  title: Text(
                    'Өөрт тохирох маршрут',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Хоног, унаагаа оруул',
                    style: TextStyle(color: colors.onPrimary),
                  ),
                  trailing: Icon(Icons.arrow_forward, color: colors.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final l in _Length.values) ...[
                    ChoiceChip(
                      label: Text(l.label),
                      selected: _length == l,
                      onSelected: (_) => setState(() => _length = l),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Энэ хугацаанд тохирох маршрут алга.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            for (final route in items) ...[
              RouteCard(route: route, onTap: () => _open(route)),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendSheet extends StatefulWidget {
  const _RecommendSheet();

  @override
  State<_RecommendSheet> createState() => _RecommendSheetState();
}

class _RecommendSheetState extends State<_RecommendSheet> {
  double _days = 5;
  bool _jeep = false;

  /// Хоногт багтах, унаанд тохирох маршрутуудыг урт нь ойрхноос эрэмбэлнэ.
  List<TravelRoute> get _matches {
    final max = _days.round();
    final list =
        travelRoutes
            .where((r) => r.dayCount <= max && (_jeep || r.vehicle != 'Жийп'))
            .toList()
          ..sort((a, b) => b.dayCount.compareTo(a.dayCount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final matches = _matches;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Өөрт тохирох маршрут', style: text.titleLarge),
          const SizedBox(height: 12),
          Text('Хэдэн өдөр аялах вэ: ${_days.round()} өдөр'),
          Slider(
            value: _days,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_days.round()}',
            onChanged: (v) => setState(() => _days = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Жийп (өндөр явах эд ангитай) унаатай'),
            value: _jeep,
            onChanged: (v) => setState(() => _jeep = v),
          ),
          const Divider(),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Тохирох маршрут олдсонгүй. Хоногоо нэмж үзээрэй.'),
            ),
          for (final r in matches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.route),
              title: Text(r.name),
              subtitle: Text(
                '${r.dayCount} өдөр · ${formatKm(r.totalKm)} км · ${r.vehicle}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(r),
            ),
        ],
      ),
    );
  }
}
