// lib/screens/offline_maps_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/routes.dart';
import '../state/offline.dart';
import '../state/subscription.dart';
import '../widgets/premium_gate.dart';

/// «Офлайн газрын зураг»: бүсээр нь маршрут, зам дээрх цэгийн өгөгдлийг
/// төхөөрөмжид татаж хадгална. Татсан бүсийн мэдээлэл өгөгдлийн санд
/// хадгалагдах тул апп дахин нээхэд хэвээр байна.
///
/// Анхаар: сургалтын хувилбарт татах явцыг дуурайлгасан. Газрын зургийн
/// хавтанг (tile) OpenStreetMap-ийн нөхцөлөөр бөөнөөр татахыг хориглодог тул
/// бодит хувилбарт өөрийн tile сервер эсвэл вектор багц шаардлагатай.
class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  final Map<String, double> _progress = {}; // татаж буй бүс → 0–1
  final Map<String, Timer> _timers = {};

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _download(OfflineRegion region) async {
    if (_timers.containsKey(region.id)) return;
    // Үнэгүй хувилбарт нэг бүс; Premium-д хязгааргүй
    final used = offlineRegionIds.value.length + _timers.length;
    if (used >= freeOfflineRegions) {
      final ok = await requirePremium(
        context,
        'Үнэгүй хувилбарт $freeOfflineRegions бүс татна. Premium-д бүх '
        'бүсийг офлайнд татаж, сүлжээгүй газар ч аялна.',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _progress[region.id] = 0);
    _timers[region.id] = Timer.periodic(const Duration(milliseconds: 120), (
      timer,
    ) {
      final next = (_progress[region.id] ?? 0) + 0.05;
      if (next >= 1) {
        timer.cancel();
        _timers.remove(region.id);
        setRegionOffline(region.id, true);
        setState(() => _progress.remove(region.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${region.name} офлайнд бэлэн боллоо')),
        );
      } else {
        setState(() => _progress[region.id] = next);
      }
    });
  }

  void _cancel(OfflineRegion region) {
    _timers.remove(region.id)?.cancel();
    setState(() => _progress.remove(region.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Офлайн газрын зураг')),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: offlineRegionIds,
        builder: (context, downloaded, _) {
          final usedMb = offlineRegions
              .where((r) => downloaded.contains(r.id))
              .fold(0, (sum, r) => sum + r.sizeMb);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.tertiary],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: colors.onPrimary, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сүлжээгүй газар ч аял',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${downloaded.length}/${offlineRegions.length} '
                            'бүс татсан · $usedMb МБ',
                            style: TextStyle(color: colors.onPrimary),
                          ),
                          ListenableBuilder(
                            listenable: subscription,
                            builder: (context, _) => Text(
                              subscription.isPremium
                                  ? 'Premium: хязгааргүй татна'
                                  : 'Үнэгүй: $freeOfflineRegions бүс хүртэл',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<bool>(
                valueListenable: wifiOnly,
                builder: (context, value, _) => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  secondary: const Icon(Icons.wifi),
                  title: const Text('Зөвхөн Wi-Fi-аар татах'),
                  subtitle: const Text('Гар утасны дата хэмнэнэ'),
                  value: value,
                  onChanged: setWifiOnly,
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Бүсүүд',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final region in offlineRegions)
                _RegionTile(
                  region: region,
                  downloaded: downloaded.contains(region.id),
                  progress: _progress[region.id],
                  onDownload: () => _download(region),
                  onCancel: () => _cancel(region),
                  onDelete: () => setRegionOffline(region.id, false),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.downloaded,
    required this.progress,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final OfflineRegion region;
  final bool downloaded;
  final double? progress; // null: татаагүй байна
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final routeCount = travelRoutes.where((r) => r.region == region.id).length;
    final downloading = progress != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                downloaded ? Icons.offline_pin : Icons.map_outlined,
                color: downloaded ? colors.primary : colors.onSurfaceVariant,
              ),
              title: Text(region.name),
              subtitle: Text(
                '${region.provinces}\n'
                '${region.sizeMb} МБ · $routeCount маршрут'
                '${downloaded ? ' · Татсан' : ''}',
              ),
              isThreeLine: true,
              trailing: downloading
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Болих',
                      onPressed: onCancel,
                    )
                  : downloaded
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Устгах',
                      onPressed: onDelete,
                    )
                  : IconButton.filledTonal(
                      icon: const Icon(Icons.download),
                      tooltip: 'Татах',
                      onPressed: onDownload,
                    ),
            ),
            if (downloading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: LinearProgressIndicator(
                  value: progress,
                  semanticsLabel: 'Татаж байна',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
