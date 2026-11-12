// lib/widgets/place_card.dart
import 'package:flutter/material.dart';

import '../models/place.dart';
import '../state/ratings.dart';
import 'favorite_button.dart';
import 'place_image.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, this.onTap});

  final Place place;
  final VoidCallback? onTap;

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
            // Үлдсэн өндрийг зураг эзэлнэ — overflow гарахаас сэргийлнэ
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceImage(image: place.imageProvider),
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
                        color: colors.surface.withValues(alpha: 0.92),
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
                    child: FavoriteButton(placeId: place.id, compact: true),
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
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 2),
                      // Хэрэглэгч үнэлгээ өгөхөд дундаж шууд шинэчлэгдэнэ
                      ValueListenableBuilder<Map<String, int>>(
                        valueListenable: userRatings,
                        builder: (context, ratings, _) {
                          final summary = ratingOf(place, ratings);
                          return Text(
                            summary.hasRating ? summary.label : 'Шинэ',
                            style: theme.textTheme.labelMedium,
                          );
                        },
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
