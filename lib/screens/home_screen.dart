import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/places.dart';
import '../models/place.dart';
import '../state/auth_service.dart';
import '../state/favorites.dart';
import '../state/ratings.dart';
import '../widgets/app_drawer.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';
  bool _showFavorites = false;
  String? _season; // null = бүх улирал
  bool _sortByRating = false;
  String _selectedId = places.first.id; // том дэлгэцэд сонгосон газар

  /// Хайлт, улирал, дуртай шүүлтүүр ба эрэмбийг хэрэглэсэн жагсаалт.
  List<Place> _visiblePlaces(Set<String> favoriteIds, Map<String, int> ratings) {
    final query = _query.trim().toLowerCase();
    final season = _season?.toLowerCase();
    final result = places.where((place) {
      final favoriteMatches = !_showFavorites || favoriteIds.contains(place.id);
      final seasonMatches =
          season == null || place.bestSeason.toLowerCase().contains(season);
      final queryMatches = query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.region.toLowerCase().contains(query) ||
          place.description.toLowerCase().contains(query) ||
          place.bestSeason.toLowerCase().contains(query);
      return favoriteMatches && seasonMatches && queryMatches;
    }).toList();
    if (_sortByRating) {
      // Дундаж үнэлгээгээр буурахаар; тэнцвэл үнэлгээний тоогоор
      result.sort((a, b) {
        final ra = ratingOf(a, ratings);
        final rb = ratingOf(b, ratings);
        final byAverage = rb.average.compareTo(ra.average);
        return byAverage != 0 ? byAverage : rb.count.compareTo(ra.count);
      });
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openDetails(Place place) => context.push('/place/${place.id}');

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'TRAVEL MONGOLIA',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.travel_explore, size: 40),
      children: const [
        Text(
          'Монгол Улсын байгалийн үзэсгэлэнт газруудыг танилцуулах сургалтын '
          'зорилготой Flutter апп. OpenStreetMap газрын зураг, Nominatim '
          'хаягийн хайлт, image_picker, Form ба ValueNotifier ашигласан.',
        ),
      ],
    );
  }

  /// “Газар нэмэх” формыг нээж, буцаасан газрыг жагсаалтын эхэнд нэмнэ.
  Future<void> _addPlace() async {
    final newPlace = await context.push<Place>('/add');
    if (!mounted || newPlace == null) return;
    setState(() {
      places.insert(0, newPlace);
      _selectedId = newPlace.id;
      _showFavorites = false;
      _season = null;
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${newPlace.name}” жагсаалтад нэмэгдлээ.')),
    );
  }

  /// Drawer-ийг хаагаад үйлдлийг гүйцэтгэнэ.
  void _fromDrawer(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Дуртай эсвэл үнэлгээ өөрчлөгдөхөд жагсаалт, эрэмбэ шууд шинэчлэгдэнэ
    return ListenableBuilder(
      listenable: Listenable.merge([favorites, userRatings]),
      builder: (context, _) {
        final visiblePlaces =
            _visiblePlaces(favorites.value, userRatings.value);

        return Scaffold(
          appBar: AppBar(
            title: const Text('TRAVEL MONGOLIA'),
            actions: [
              IconButton(
                tooltip: 'Хайх',
                onPressed: () => _searchFocusNode.requestFocus(),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Газрын зураг',
                onPressed: () => context.push('/places-map'),
                icon: const Icon(Icons.map_outlined),
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: AppDrawer(
            showingFavorites: _showFavorites,
            onAllPlaces: () =>
                _fromDrawer(() => setState(() => _showFavorites = false)),
            onFavorites: () =>
                _fromDrawer(() => setState(() => _showFavorites = true)),
            onMap: () => _fromDrawer(() => context.push('/places-map')),
            onSettings: () => _fromDrawer(() => context.push('/settings')),
            onAbout: () => _fromDrawer(_showAboutDialog),
            onLogout: () => _fromDrawer(auth.logout),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addPlace,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Газар нэмэх'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          colors.primaryContainer,
                          colors.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Монгол орныг\nөөр өнцгөөс нээ',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.onPrimaryContainer,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Байгаль, уул ус, хээр талын аяллаа төлөвлөөрэй.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.terrain_rounded,
                            size: 64, color: colors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Газар, аймаг эсвэл улирлаар хайх',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Арилгах',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Улирлын шүүлтүүр ба үнэлгээгээр эрэмбэлэх сонголт
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          avatar: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Үнэлгээгээр'),
                          tooltip: 'Дундаж үнэлгээгээр эрэмбэлэх',
                          selected: _sortByRating,
                          showCheckmark: false,
                          onSelected: (v) => setState(() => _sortByRating = v),
                        ),
                        const SizedBox(width: 12),
                        for (final s in seasons) ...[
                          ChoiceChip(
                            label: Text(s),
                            selected: _season == s,
                            onSelected: (v) =>
                                setState(() => _season = v ? s : null),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _showFavorites ? 'Дуртай газрууд' : 'Байгалийн газрууд',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        '${visiblePlaces.length} газар',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (visiblePlaces.isEmpty) {
                          return _EmptyState(
                            showingFavorites: _showFavorites,
                            filtered: _query.trim().isNotEmpty ||
                                _season != null,
                          );
                        }
                        if (constraints.maxWidth >= 840) {
                          return _buildWideLayout(
                              context, constraints.maxWidth, visiblePlaces);
                        }
                        return _buildGridLayout(
                            constraints.maxWidth, visiblePlaces);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridLayout(double width, List<Place> items) {
    final columns = width >= 600 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 92, top: 4),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: columns == 2 ? 0.73 : 0.76,
      ),
      itemBuilder: (context, index) {
        final place = items[index];
        return PlaceCard(
          key: ValueKey(place.id),
          place: place,
          onTap: () => _openDetails(place),
        );
      },
    );
  }

  Widget _buildWideLayout(
      BuildContext context, double width, List<Place> items) {
    final colors = Theme.of(context).colorScheme;
    final selected = items.where((p) => p.id == _selectedId).firstOrNull ??
        items.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: width >= 1100 ? 330 : 285,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88, right: 8),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final place = items[index];
              final summary = ratingOf(place);
              return ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                selected: place.id == selected.id,
                selectedTileColor: colors.secondaryContainer,
                leading: CircleAvatar(
                  foregroundImage: place.imageProvider,
                  onForegroundImageError: place.imageProvider == null
                      ? null
                      : (exception, stackTrace) {},
                  child: const Icon(Icons.landscape_outlined),
                ),
                title: Text(place.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${place.region} · ★ '
                  '${summary.hasRating ? summary.label : 'Шинэ'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isFavorite(place.id)
                    ? Icon(Icons.favorite, size: 17, color: colors.error)
                    : null,
                onTap: () => setState(() => _selectedId = place.id),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: colors.surfaceContainerLowest,
              child: PlaceDetailView(place: selected),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showingFavorites, required this.filtered});

  final bool showingFavorites;

  /// Хайлт эсвэл улирлын шүүлтүүр идэвхтэй эсэх.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showingFavorites ? Icons.favorite_border : Icons.travel_explore,
              size: 58,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              filtered
                  ? 'Таны хайлтад тохирох газар олдсонгүй.'
                  : 'Одоогоор дуртай газар алга.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Өөр нэр, аймаг эсвэл улирлаар хайж үзээрэй.'
                  : 'Карт дээрх зүрхэн товчийг дарж дуртай газраа хадгална уу.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
