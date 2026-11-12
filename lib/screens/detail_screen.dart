// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/picked_location.dart';
import '../models/place.dart';
import '../state/ratings.dart';
import '../utils/geo.dart';
import '../widgets/favorite_button.dart';
import '../widgets/place_image.dart';
import '../widgets/rating_input.dart';
import '../widgets/star_rating.dart';
import 'map_picker_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(place.name)),
        body: PlaceDetailView(place: place),
      );
}

/// Scaffold-гүй дэлгэрэнгүй хэсэг. Том дэлгэцийн master-detail layout-д ашиглана.
class PlaceDetailView extends StatelessWidget {
  const PlaceDetailView({super.key, required this.place});

  final Place place;

  void _rate(BuildContext context, int stars) {
    ratePlace(place.id, stars);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('«${place.name}»-д $stars од өглөө'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openMap(BuildContext context) {
    context.push(
      '/map',
      extra: MapPickerArgs(
        readOnly: true,
        title: place.name,
        initial: PickedLocation(
          latitude: place.latitude!,
          longitude: place.longitude!,
          name: place.name,
          address: place.region,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // key: том дэлгэцэд өөр газар сонгоход хуудасны байрлал шинэчлэгдэнэ
        _Gallery(key: ValueKey(place.id), place: place),
        // Үнэлгээ өгөхөд дундаж, тоо, “таны үнэлгээ” шууд шинэчлэгдэнэ
        ValueListenableBuilder<Map<String, int>>(
          valueListenable: userRatings,
          builder: (context, ratings, _) {
            final summary = ratingOf(place, ratings);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: summary.hasRating
                      ? Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            StarRating(rating: summary.average),
                            Text(summary.label, style: text.titleMedium),
                            Text(
                              '(${summary.count} үнэлгээ)',
                              style: text.bodySmall,
                            ),
                          ],
                        )
                      : Text(
                          'Шинэ газар — үнэлгээ хараахан алга',
                          style: text.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                ),
                _RateCard(
                  mine: summary.mine,
                  onRate: (stars) => _rate(context, stars),
                ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.place_outlined,
                  label: 'Байршил',
                  value: place.region,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  icon: Icons.route_outlined,
                  label: 'Ойролцоо зай',
                  value: place.distanceKm > 0
                      ? '~${place.distanceKm} км'
                      : 'Тодорхойгүй',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Тохиромжтой',
                  value: place.bestSeason,
                ),
              ),
            ],
          ),
        ),
        if (place.hasLocation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              color: colors.secondaryContainer,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Газрын зураг дээр харах'),
                subtitle: Text(
                  formatCoordinates(place.latitude!, place.longitude!),
                ),
                trailing: const Icon(Icons.map_outlined),
                onTap: () => _openMap(context),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Text(
            'Товч мэдээлэл',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Text(
            place.description,
            style: text.bodyLarge?.copyWith(height: 1.65),
          ),
        ),
      ],
    );
  }
}

/// Толгой хэсэг: зургуудыг PageView-ээр гүйлгэж харуулна; дээр нь нэр,
/// дуртай товч, хуудасны цэгүүд.
class _Gallery extends StatefulWidget {
  const _Gallery({super.key, required this.place});

  final Place place;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final text = Theme.of(context).textTheme;
    final images = place.imageProviders;

    return SizedBox(
      height: 285,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.length <= 1)
            PlaceImage(
              image: images.isEmpty ? null : images.first,
              semanticLabel: '${place.name} — зураг',
            )
          else
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => PlaceImage(
                image: images[i],
                semanticLabel:
                    '${place.name} — зураг ${i + 1}/${images.length}',
              ),
            ),
          // Гүйлгэх хөдөлгөөнд саад болохгүйн тулд IgnorePointer
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.42, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 72,
            bottom: 24,
            child: IgnorePointer(
              child: Text(
                place.name,
                style: text.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < images.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 16,
            child: FavoriteButton(placeId: place.id),
          ),
        ],
      ),
    );
  }
}

/// “Үнэлгээ өгөх” хэсэг: 5 од дээр дарж үнэлнэ, дахин дарж өөрчилнө.
class _RateCard extends StatelessWidget {
  const _RateCard({required this.mine, required this.onRate});

  final int? mine;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                mine == null ? 'Энэ газрыг үнэлэх' : 'Таны үнэлгээ: $mine/5',
                style: text.titleSmall,
              ),
              FittedBox(
                // Нарийн дэлгэц/том текстэд 5 од багтахгүй бол жижигрүүлнэ
                fit: BoxFit.scaleDown,
                child: RatingInput(value: mine ?? 0, onChanged: onRate),
              ),
              if (mine == null)
                Text('Од дээр дарж үнэлгээ өгнө үү', style: text.bodySmall),
            ],
          ),
        ),
      ),
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
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
