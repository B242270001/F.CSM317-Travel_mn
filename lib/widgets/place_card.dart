import 'package:flutter/material.dart';

import '../models/place.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Place place;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'place-image-${place.id}',
                    child: Image.asset(
                      place.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: colors.surfaceContainerHighest,
                        child: Icon(
                          Icons.landscape_outlined,
                          size: 48,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 145),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        place.bestSeason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      tooltip: isFavorite ? 'Дуртайгаас хасах' : 'Дуртайд нэмэх',
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? colors.error : colors.onSurface,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface.withOpacity(0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
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
                      const SizedBox(width: 5),
                      Icon(Icons.star_rounded, size: 16, color: colors.tertiary),
                      const SizedBox(width: 2),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: theme.textTheme.labelMedium,
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
