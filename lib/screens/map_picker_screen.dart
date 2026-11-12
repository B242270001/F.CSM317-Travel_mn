// lib/screens/map_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/picked_location.dart';
import '../services/geocoding_service.dart';
import '../utils/geo.dart';

/// Газрын зургийн дэлгэцийн тохиргоо (go_router-ийн `extra`-гаар дамжина).
class MapPickerArgs {
  const MapPickerArgs({this.initial, this.readOnly = false, this.title});

  final PickedLocation? initial; // эхлээд харуулах цэг
  final bool readOnly; // true: зөвхөн харах (дэлгэрэнгүй дэлгэцээс)
  final String? title;
}

/// OpenStreetMap дээр байршил хайх, дарж тэмдэглэх, сонгосон байршлыг
/// `context.pop(PickedLocation)`-оор буцаах дэлгэц. API түлхүүр шаардахгүй.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.args = const MapPickerArgs()});

  final MapPickerArgs args;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _mongolia = LatLng(46.8625, 103.8467); // Монголын төв
  static const _minZoom = 3.0;
  static const _maxZoom = 18.0;

  final _query = TextEditingController();
  final _map = MapController();
  PickedLocation? _picked;
  List<PickedLocation> _results = const [];
  bool _searching = false;
  bool _resolving = false; // сонгосон цэгийн хаягийг тодорхойлж байна
  int _requestId = 0;

  bool get _readOnly => widget.args.readOnly;

  @override
  void initState() {
    super.initState();
    _picked = widget.args.initial;
  }

  @override
  void dispose() {
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Газрын зураг дээр дарсан цэг.
  Future<void> _selectPoint(LatLng point) async {
    final id = ++_requestId;
    setState(() {
      _picked = PickedLocation(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      _results = const [];
      _resolving = true;
    });
    try {
      final location = await Geocoding.reverse(point.latitude, point.longitude);
      if (!mounted || id != _requestId) return;
      setState(() {
        _resolving = false;
        if (location != null) _picked = location;
      });
    } on GeocodingException catch (e) {
      // Хаяг олдохгүй ч координат хэвээр — сонгож болно
      if (!mounted || id != _requestId) return;
      setState(() => _resolving = false);
      _showError(e.message);
    }
  }

  /// Хайлтын үр дүнгээс сонгох: газрын зургийг шилжүүлж, маркер тавина.
  void _selectResult(PickedLocation location) {
    _requestId++; // хүлээгдэж буй reverse хариуг цуцална
    setState(() {
      _picked = location;
      _results = const [];
      _resolving = false;
    });
    _map.move(LatLng(location.latitude, location.longitude), 11);
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final results = await Geocoding.search(query);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = results;
      });
      if (results.isEmpty) {
        _showError('«$query» олдсонгүй. Өөр нэрээр хайж үзнэ үү.');
      } else if (results.length == 1) {
        _selectResult(results.first);
      }
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      _showError(e.message);
    }
  }

  void _zoom(double delta) {
    final camera = _map.camera;
    _map.move(
      camera.center,
      (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picked = _picked;
    final initial = widget.args.initial;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _readOnly ? (widget.args.title ?? 'Байршил') : 'Байршил сонгох',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: initial == null
                        ? _mongolia
                        : LatLng(initial.latitude, initial.longitude),
                    initialZoom: initial == null ? 4.6 : 10,
                    minZoom: _minZoom,
                    maxZoom: _maxZoom,
                    onTap: _readOnly ? null : (_, point) => _selectPoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      // OSM-ийн нөхцөл: апп-аа танилцуулах User-Agent
                      userAgentPackageName: appPackageName,
                      maxNativeZoom: 19,
                    ),
                    if (picked != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(picked.latitude, picked.longitude),
                            width: 48,
                            height: 48,
                            // Зүүний үзүүр яг цэг дээр байхаар дээш нь байрлуулна
                            alignment: Alignment.topCenter,
                            child: Icon(
                              Icons.location_pin,
                              size: 48,
                              color: scheme.error,
                              semanticLabel: 'Сонгосон байршил',
                            ),
                          ),
                        ],
                      ),
                    // OSM-ийн нөхцөл: эх сурвалжийг заавал харуулна
                    const SimpleAttributionWidget(
                      source: Text('OpenStreetMap contributors'),
                    ),
                  ],
                ),
                if (!_readOnly)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _SearchPanel(
                      controller: _query,
                      searching: _searching,
                      results: _results,
                      onSearch: _search,
                      onSelect: _selectResult,
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 44, // эх сурвалжийн бичгийн дээр
                  child: Column(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: 'Томруулах',
                        onPressed: () => _zoom(1),
                      ),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        tooltip: 'Жижигрүүлэх',
                        onPressed: () => _zoom(-1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _InfoPanel(
            picked: picked,
            resolving: _resolving,
            readOnly: _readOnly,
            onConfirm: () => context.pop(picked),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.searching,
    required this.results,
    required this.onSearch,
    required this.onSelect,
  });

  final TextEditingController controller;
  final bool searching;
  final List<PickedLocation> results;
  final VoidCallback onSearch;
  final ValueChanged<PickedLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Газар, сум, аймаг хайх',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Хайж байна',
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      tooltip: 'Хайх',
                      onPressed: onSearch,
                    ),
            ),
          ),
          if (results.length > 1) ...[
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final r in results)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(r.name ?? r.address ?? r.coordinates),
                      subtitle: r.address == null
                          ? null
                          : Text(
                              r.address!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => onSelect(r),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Доод самбар: сонгосон байршлын нэр, хаяг, координат ба “Сонгох” товч.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.picked,
    required this.resolving,
    required this.readOnly,
    required this.onConfirm,
  });

  final PickedLocation? picked;
  final bool resolving;
  final bool readOnly;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final p = picked;
    return Material(
      elevation: 8,
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (p == null)
                Text(
                  'Газрын зураг дээр дарж эсвэл дээрх талбараар хайж '
                  'байршлаа сонгоно уу.',
                  style: text.bodyMedium,
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name ?? p.region ?? 'Сонгосон цэг',
                            style: text.titleMedium,
                          ),
                          if (p.address != null)
                            Text(
                              p.address!,
                              style: text.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            '${p.coordinates} · Улаанбаатараас ~'
                            '${distanceFromUbKm(p.latitude, p.longitude)} км',
                            style: text.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (resolving) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                    semanticsLabel: 'Хаяг тодорхойлж байна',
                  ),
                ],
              ],
              if (!readOnly) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: p == null || resolving ? null : onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Энэ байршлыг сонгох'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
