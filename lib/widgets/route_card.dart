// lib/widgets/route_card.dart
import 'package:flutter/material.dart';

import '../models/travel_route.dart';
import '../state/favorites.dart';

/// 1850 → «1,850»
String formatKm(int km) => km.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]},',
);

/// 1400000 → «1.4 сая₮», 850000 → «850 мянга₮»
String formatCost(int tugrug) => tugrug >= 1000000
    ? '${(tugrug / 1000000).toStringAsFixed(1)} сая₮'
    : '${(tugrug / 1000).round()} мянга₮';

/// Бэлэн маршрутын карт: зураг, хоног, тэмдэг, зам, км, зогсоол, унаа.
class RouteCard extends StatelessWidget {
  const RouteCard({super.key, required this.route, this.onTap});

  final TravelRoute route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    route.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: colors.surfaceContainerHighest),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _Pill(
                      icon: Icons.calendar_today,
                      label: '${route.dayCount} өдөр',
                      background: Colors.black54,
                      foreground: Colors.white,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _Pill(
                      label: route.badge,
                      background: Colors.amber.shade600,
                      foreground: Colors.black87,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: RouteFavoriteButton(routeId: route.id),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        route.rating.toStringAsFixed(1),
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Pill(
                        icon: Icons.route,
                        label: '${formatKm(route.totalKm)} км',
                        background: colors.surfaceContainerHigh,
                        foreground: colors.onSurface,
                      ),
                      _Pill(
                        icon: Icons.place_outlined,
                        label: '${route.stopCount} зогсоол',
                        background: colors.surfaceContainerHigh,
                        foreground: colors.onSurface,
                      ),
                      _Pill(
                        icon: Icons.directions_car_outlined,
                        label: route.vehicle,
                        background: colors.surfaceContainerHigh,
                        foreground: colors.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Маршрутыг дуртайд нэмэх / хасах товч.
class RouteFavoriteButton extends StatelessWidget {
  const RouteFavoriteButton({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favoriteRoutes,
      builder: (context, ids, _) {
        final selected = ids.contains(routeId);
        return IconButton.filledTonal(
          tooltip: selected ? 'Дуртайгаас хасах' : 'Дуртайд нэмэх',
          onPressed: () => toggleFavoriteRoute(routeId),
          style: IconButton.styleFrom(
            backgroundColor: colors.surface.withValues(alpha: 0.92),
          ),
          icon: Icon(
            selected ? Icons.favorite : Icons.favorite_border,
            color: selected ? colors.error : colors.onSurface,
          ),
        );
      },
    );
  }
}
