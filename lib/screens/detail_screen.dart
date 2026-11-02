import 'package:flutter/material.dart';

import '../models/place.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.place,
    required this.initialFavorite,
    required this.onFavoriteChanged,
  });

  final Place place;
  final bool initialFavorite;
  final ValueChanged<Place> onFavoriteChanged;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialFavorite;
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged(widget.place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.place.name)),
      body: PlaceDetailView(
        place: widget.place,
        isFavorite: _isFavorite,
        onFavoriteToggle: _toggleFavorite,
      ),
    );
  }
}

/// Scaffold-гүй дэлгэрэнгүй хэсэг. Том дэлгэцийн master-detail layout-д ашиглана.
class PlaceDetailView extends StatelessWidget {
  const PlaceDetailView({
    super.key,
    required this.place,
    required this.isFavorite,
    this.onFavoriteToggle,
  });

  final Place place;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            Hero(
              tag: 'place-image-${place.id}',
              child: Image.asset(
                place.image,
                height: 285,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 285,
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.landscape_outlined, size: 72, color: colors.onSurfaceVariant),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.68)],
                    stops: const [0.42, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 72,
              bottom: 18,
              child: Text(
                place.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: IconButton.filledTonal(
                tooltip: isFavorite ? 'Дуртайгаас хасах' : 'Дуртайд нэмэх',
                onPressed: onFavoriteToggle,
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface.withOpacity(0.94),
                ),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? colors.error : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _Stat(icon: Icons.star_rounded, label: 'Үнэлгээ', value: place.rating.toStringAsFixed(1))),
              const SizedBox(width: 8),
              Expanded(child: _Stat(icon: Icons.route_outlined, label: 'Ойролцоо зай', value: place.distanceKm == 0 ? 'Тодорхойгүй' : '~${place.distanceKm} км')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(icon: Icons.wb_sunny_outlined, label: 'Тохиромжтой', value: place.bestSeason)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Text('Товч мэдээлэл', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Text(
            place.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Card(
            color: colors.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, color: colors.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Байршил', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.onSecondaryContainer)),
                        const SizedBox(height: 4),
                        Text(place.region, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSecondaryContainer)),
                        const SizedBox(height: 10),
                        Text(
                          'Зай нь Улаанбаатараас тооцсон ойролцоо мэдээлэл бөгөөд сонгосон маршрут, замын нөхцөлөөс хамаарч өөрчлөгдөнө.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSecondaryContainer, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
