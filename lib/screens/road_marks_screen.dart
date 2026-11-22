// lib/screens/road_marks_screen.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/hazards.dart';
import '../models/road_mark.dart';
import '../models/travel_route.dart';
import '../state/road_marks.dart';
import '../state/subscription.dart';
import '../utils/geo.dart';
import '../widgets/premium_gate.dart';
import '../widgets/route_map.dart';

/// «Замын тэмдэглэгээ»: хэрэглэгч маршрутын газрын зураг дээр удаан дарж
/// муу зам, гол гатлам, шалган нэвтрүүлэх цэг гэх мэтийг тэмдэглэнэ.
/// Тэмдэглэгээ өгөгдлийн санд хадгалагдаж, маршрутын бүх газрын зурагт
/// харагдана — дараагийн удаа эсвэл сүлжээгүй үед ч ашиглана.
class RoadMarksScreen extends StatefulWidget {
  const RoadMarksScreen({super.key, required this.route});

  final TravelRoute route;

  @override
  State<RoadMarksScreen> createState() => _RoadMarksScreenState();
}

class _RoadMarksScreenState extends State<RoadMarksScreen> {
  RoadMarkType? _type; // null = бүгд

  TravelRoute get route => widget.route;

  /// Газрын зураг дээр удаан дарсан цэгт шинэ тэмдэглэгээ нэмнэ.
  Future<void> _add(LatLng point) async {
    final count = marksOf(route.id).length;
    if (count >= freeRoadMarksPerRoute) {
      final ok = await requirePremium(
        context,
        'Үнэгүй хувилбарт маршрут бүрт $freeRoadMarksPerRoute хүртэл '
        'тэмдэглэгээ хийнэ. Premium-д хязгааргүй.',
      );
      if (!ok || !mounted) return;
    }
    final result = await showModalBottomSheet<(RoadMarkType, String)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AddMarkSheet(point: point),
    );
    if (result == null || !mounted) return;
    final (type, note) = result;
    addRoadMark(
      routeId: route.id,
      type: type,
      note: note,
      latitude: point.latitude,
      longitude: point.longitude,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('«${type.label}» тэмдэглэгдлээ')));
  }

  void _show(RoadMark m) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: m.type.color,
                child: Icon(m.type.icon, color: Colors.white),
              ),
              title: Text(m.type.label),
              subtitle: Text(_date(m.createdAt)),
            ),
            if (m.note.isNotEmpty) ...[
              Text(m.note, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
            ],
            Text('Координат: ${formatCoordinates(m.latitude, m.longitude)}'),
            Text(
              'УБ-аас шулуунаар: '
              '${distanceFromUbKm(m.latitude, m.longitude)} км',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  removeRoadMark(m.id);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Устгах'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year}.${_two(d.month)}.${_two(d.day)} '
      '${_two(d.hour)}:${_two(d.minute)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Замын тэмдэглэгээ')),
      body: ListenableBuilder(
        listenable: Listenable.merge([roadMarks, subscription]),
        builder: (context, _) {
          final all = marksOf(route.id);
          final items = _type == null
              ? all
              : all.where((m) => m.type == _type).toList();
          final premium = subscription.isPremium;
          final hazards = hazardsOf(
            route.id,
          ).where((h) => _type == null || h.type == _type).toList();

          return Column(
            children: [
              SizedBox(
                height: 280,
                child: RouteMap(
                  route: route,
                  marks: items,
                  onMarkTap: _show,
                  onLongPress: _add,
                ),
              ),
              Container(
                width: double.infinity,
                color: colors.secondaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Газрын зураг дээр удаан дарж (компьютерт баруун '
                        'товч) тэмдэглэнэ',
                        style: TextStyle(color: colors.onSecondaryContainer),
                      ),
                    ),
                    premium
                        ? const PremiumBadge(compact: true)
                        : Text(
                            '${all.length}/$freeRoadMarksPerRoute',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                  ],
                ),
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
                    for (final t in RoadMarkType.values) ...[
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
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Апп-д урьдчилан орсон анхааруулга — бүх хэрэглэгчид ижил
                    if (hazards.isNotEmpty) ...[
                      _SectionTitle(
                        'Маршрутын анхааруулга (${hazards.length})',
                      ),
                      for (final h in hazards)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: h.type.color,
                            child: Icon(
                              h.type.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(h.title),
                          subtitle: Text(
                            h.note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => showHazardSheet(context, h),
                        ),
                    ],
                    _SectionTitle('Миний тэмдэглэгээ (${items.length})'),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Text(
                          all.isEmpty
                              ? 'Одоогоор тэмдэглэгээ алга. Зам дээрх '
                                    'анхаарах зүйлсээ тэмдэглэж аваарай.'
                              : 'Энэ төрлийн тэмдэглэгээ алга.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    for (final m in items)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: m.type.color,
                          child: Icon(
                            m.type.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(m.type.label),
                        subtitle: Text(
                          m.note.isEmpty ? _date(m.createdAt) : m.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Устгах',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => removeRoadMark(m.id),
                        ),
                        onTap: () => _show(m),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Шинэ тэмдэглэгээний төрөл, тайлбар оруулах хуудас.
class _AddMarkSheet extends StatefulWidget {
  const _AddMarkSheet({required this.point});

  final LatLng point;

  @override
  State<_AddMarkSheet> createState() => _AddMarkSheetState();
}

class _AddMarkSheetState extends State<_AddMarkSheet> {
  RoadMarkType _type = RoadMarkType.badRoad;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Шинэ тэмдэглэгээ', style: text.titleLarge),
          Text(
            formatCoordinates(widget.point.latitude, widget.point.longitude),
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final t in RoadMarkType.values)
                ChoiceChip(
                  avatar: Icon(t.icon, size: 16, color: t.color),
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Тайлбар (заавал биш)',
              hintText: 'Жишээ нь: Борооны дараа шавартай',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop((_type, _note.text)),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Тэмдэглэх'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
