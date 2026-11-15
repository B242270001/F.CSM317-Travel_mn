// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/places.dart';
import '../data/routes.dart';
import '../state/favorites.dart';
import '../state/ratings.dart';
import '../widgets/favorite_button.dart';
import '../widgets/place_image.dart';
import '../widgets/route_card.dart';

/// «Дуртай»: хадгалсан газар ба маршрутууд.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Дуртай'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Газрууд'),
              Tab(text: 'Маршрутууд'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([
            favorites,
            favoriteRoutes,
            userRatings,
          ]),
          builder: (context, _) {
            final favPlaces = places.where((p) => isFavorite(p.id)).toList();
            final favRoutes = travelRoutes
                .where((r) => favoriteRoutes.value.contains(r.id))
                .toList();
            return TabBarView(
              children: [
                favPlaces.isEmpty
                    ? const _Empty('Одоогоор дуртай газар алга.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: favPlaces.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final place = favPlaces[i];
                          final summary = ratingOf(place);
                          return Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/place/${place.id}'),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 96,
                                    height: 84,
                                    child: PlaceImage(
                                      image: place.imageProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${place.region} · ★ '
                                          '${summary.hasRating ? summary.label : 'Шинэ'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  FavoriteButton(
                                    placeId: place.id,
                                    compact: true,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                favRoutes.isEmpty
                    ? const _Empty('Одоогоор дуртай маршрут алга.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: favRoutes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, i) => RouteCard(
                          route: favRoutes[i],
                          onTap: () =>
                              context.push('/route/${favRoutes[i].id}'),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

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
              Icons.favorite_border,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Зүрхэн товчийг дарж хадгална уу.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
