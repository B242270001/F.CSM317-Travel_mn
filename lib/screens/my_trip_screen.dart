// lib/screens/my_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/travel_route.dart';
import '../state/trip.dart';
import '../widgets/route_card.dart';
import 'route_detail_screen.dart' show formatHours;

/// «Миний аялал»: идэвхтэй аяллын өдөр бүрийн явц, дараагийн шатахуун,
/// авч явах зүйлсийн жагсаалт. Бүгд офлайн ажиллана.
class MyTripScreen extends StatefulWidget {
  const MyTripScreen({super.key});

  @override
  State<MyTripScreen> createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  final _newItem = TextEditingController();

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  void _addItem() {
    if (trip.addItem(_newItem.text)) {
      _newItem.clear();
    } else if (_newItem.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Энэ зүйл жагсаалтад байна')),
      );
    }
  }

  Future<void> _endTrip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Аяллыг дуусгах уу?'),
        content: const Text('Явц болон жагсаалт устана.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Дуусгах'),
          ),
        ],
      ),
    );
    if (ok == true) trip.end();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: trip,
      builder: (context, _) {
        final route = trip.route;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Миний аялал'),
            actions: [
              if (route != null)
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Аяллыг дуусгах',
                  onPressed: _endTrip,
                ),
            ],
          ),
          body: route == null ? const _NoTrip() : _buildTrip(context, route),
        );
      },
    );
  }

  Widget _buildTrip(BuildContext context, TravelRoute route) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fuel = trip.nextFuelStop;
    final current = trip.currentDay;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [colors.primary, colors.tertiary]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                current == null
                    ? 'Аялал дууслаа. Баяр хүргэе!'
                    : '${current + 1}-р өдөр · ${route.days[current].title}',
                style: TextStyle(color: colors.onPrimary),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: trip.progress,
                  minHeight: 8,
                  backgroundColor: colors.onPrimary.withValues(alpha: 0.25),
                  color: colors.onPrimary,
                  semanticsLabel: 'Аяллын явц',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${trip.doneCount}/${route.dayCount} өдөр · '
                '${formatKm(trip.kmDone)}/${formatKm(route.totalKm)} км',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (fuel != null) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: fuel.kmAway >= 200
                ? colors.errorContainer
                : colors.secondaryContainer,
            child: ListTile(
              leading: Icon(
                fuel.kmAway >= 200
                    ? Icons.warning_amber
                    : Icons.local_gas_station,
              ),
              title: Text('Дараагийн шатахуун ${fuel.kmAway} км дараа'),
              subtitle: Text(fuel.poi.place),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/route/${route.id}/roadside'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Өдрийн явц',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        for (var i = 0; i < route.days.length; i++)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: trip.isDayDone(i),
            onChanged: (_) => trip.toggleDay(i),
            title: Text(
              '${i + 1}-р өдөр · ${route.days[i].title}',
              style: TextStyle(
                decoration: trip.isDayDone(i)
                    ? TextDecoration.lineThrough
                    : null,
                fontWeight: i == current ? FontWeight.w700 : null,
              ),
            ),
            subtitle: Text(
              '${route.days[i].km} км · '
              '~${formatHours(route.days[i].hours)} цаг · '
              '${route.days[i].stay}\n'
              'УБ-аас нийт ${formatKm(route.kmAfterDays(i + 1))} км',
            ),
            isThreeLine: true,
          ),
        const Divider(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Авч явах зүйлс',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text('${trip.packedCount}/${trip.checklist.length} бэлэн'),
          ],
        ),
        for (final entry in trip.checklist.entries)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: entry.value,
            onChanged: (_) => trip.toggleItem(entry.key),
            title: Text(entry.key),
            secondary: IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Хасах',
              onPressed: () => trip.removeItem(entry.key),
            ),
          ),
        const SizedBox(height: 4),
        TextField(
          controller: _newItem,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addItem(),
          decoration: InputDecoration(
            hintText: 'Шинэ зүйл нэмэх',
            prefixIcon: const Icon(Icons.add),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Нэмэх',
              onPressed: _addItem,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoTrip extends StatelessWidget {
  const _NoTrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 64,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Идэвхтэй аялал алга',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Бэлэн маршрутаас сонгоод «Аялалд нэмэх» дарна уу.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/?tab=1'),
              icon: const Icon(Icons.route),
              label: const Text('Маршрут сонгох'),
            ),
          ],
        ),
      ),
    );
  }
}
