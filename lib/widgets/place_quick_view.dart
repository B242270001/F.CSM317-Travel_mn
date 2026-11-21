// lib/widgets/place_quick_view.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/place.dart';
import '../state/favorites.dart';
import '../state/place_order.dart';
import '../state/ratings.dart';
import 'favorite_button.dart';
import 'place_image.dart';

String _distanceLabel(Place p) {
  final km = placeDistanceKm(p);
  return km >= 1 << 30 ? 'Тодорхойгүй' : '$km км';
}

/// Жагсаалтын нэг мөр: зураг, нэр, аймаг, үнэлгээ, зай, улирал.
class PlaceListTile extends StatelessWidget {
  const PlaceListTile({
    super.key,
    required this.place,
    required this.onTap,
    this.trailing,
    this.highlighted = false,
    this.showRegion = true,
  });

  /// Аймгийн нэрийг харуулах эсэх (бүсээр бүлэглэсэн үед давхардахгүй).
  final bool showRegion;

  final Place place;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Дараалал засах үед хүрээгээр тодотгоно.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = ratingOf(place);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.primary, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: PlaceImage(image: place.imageProvider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (showRegion)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              place.region,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      children: [
                        _Mini(
                          Icons.star_rounded,
                          summary.hasRating ? summary.label : 'Шинэ',
                          Colors.amber,
                        ),
                        _Mini(
                          Icons.directions_car_outlined,
                          _distanceLabel(place),
                          colors.primary,
                        ),
                        _Mini(
                          Icons.wb_sunny_outlined,
                          place.bestSeason,
                          colors.tertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 2),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// Жагсаалтын газар дээр дарахад гарах товч мэдээлэл: том зураг,
/// үнэлгээ, зай, улирал, координат, тайлбар — «Дэлгэрэнгүй» рүү шилжинэ.
Future<void> showPlaceQuickView(BuildContext context, Place place) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _QuickView(place: place),
  );
}

class _QuickView extends StatelessWidget {
  const _QuickView({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlaceImage(
                      image: place.imageProvider,
                      semanticLabel: place.name,
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: FavoriteButton(placeId: place.id, compact: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              place.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colors.primary),
                const SizedBox(width: 3),
                Text(place.region, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<Map<String, int>>(
              valueListenable: userRatings,
              builder: (context, ratings, _) {
                final summary = ratingOf(place, ratings);
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.6,
                  children: [
                    _InfoBox(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      label: 'Үнэлгээ',
                      value: summary.hasRating
                          ? '${summary.label} (${summary.count})'
                          : 'Үнэлгээгүй',
                    ),
                    _InfoBox(
                      icon: Icons.directions_car_outlined,
                      label: 'УБ-аас',
                      value: _distanceLabel(place),
                    ),
                    _InfoBox(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Улирал',
                      value: place.bestSeason,
                    ),
                    _InfoBox(
                      icon: Icons.my_location,
                      label: 'Координат',
                      value: place.hasLocation
                          ? '${place.latitude!.toStringAsFixed(2)}, '
                                '${place.longitude!.toStringAsFixed(2)}'
                          : 'Тодорхойгүй',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              place.description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: favorites,
                    builder: (context, ids, _) {
                      final fav = ids.contains(place.id);
                      return OutlinedButton.icon(
                        onPressed: () => toggleFavorite(place.id),
                        icon: Icon(
                          fav ? Icons.favorite : Icons.favorite_border,
                          color: fav ? colors.error : null,
                        ),
                        label: Text(fav ? 'Дуртай' : 'Хадгалах'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/place/${place.id}');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Дэлгэрэнгүй'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
