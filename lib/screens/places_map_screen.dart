// lib/screens/places_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../data/places.dart';

/// “Газрын зураг” дэлгэц: координаттай бүх газрыг marker-ээр харуулна.
/// Marker дарахад тухайн газрын дэлгэрэнгүй дэлгэц нээгдэнэ.
class PlacesMapScreen extends StatefulWidget {
  const PlacesMapScreen({super.key});

  @override
  State<PlacesMapScreen> createState() => _PlacesMapScreenState();
}

class _PlacesMapScreenState extends State<PlacesMapScreen> {
  static const _mongolia = LatLng(46.8625, 103.8467); // Монголын төв
  static const _minZoom = 3.0;
  static const _maxZoom = 18.0;

  final _map = MapController();

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
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
    final located = places.where((p) => p.hasLocation).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Газрын зураг')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: const MapOptions(
              initialCenter: _mongolia,
              initialZoom: 4.6,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: appPackageName,
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  for (final place in located)
                    Marker(
                      point: LatLng(place.latitude!, place.longitude!),
                      width: 48,
                      height: 48,
                      // Зүүний үзүүр яг цэг дээр байхаар дээш нь байрлуулна
                      alignment: Alignment.topCenter,
                      child: Tooltip(
                        message: place.name,
                        child: GestureDetector(
                          onTap: () => context.push('/place/${place.id}'),
                          child: Icon(
                            Icons.location_pin,
                            size: 48,
                            color: scheme.error,
                            semanticLabel: place.name,
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
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('${located.length} газар · тэмдэг дээр дарна уу'),
              ),
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
    );
  }
}
