import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/places.dart';
import '../data/zones.dart';
import '../models/place.dart';
import '../state/auth_service.dart';
import '../state/favorites.dart';
import '../state/place_order.dart';
import '../state/ratings.dart';
import '../state/store.dart';
import '../state/trip.dart';
import '../widgets/app_drawer.dart';
import '../widgets/place_quick_view.dart';
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
  PlaceSort _sort = PlaceSort.custom;
  String? _zone; // null = бүх бүс
  final Set<String> _collapsed = {}; // хураасан бүсүүдийн id
  bool _reordering = false; // «Миний дараалал» засах горим
  String _selectedId = places.first.id; // том дэлгэцэд сонгосон газар

  /// Хайлт, улирал, дуртай шүүлтүүр ба эрэмбийг хэрэглэсэн жагсаалт.
  List<Place> _visiblePlaces(
    Set<String> favoriteIds,
    Map<String, int> ratings,
  ) {
    final query = _query.trim().toLowerCase();
    final season = _season?.toLowerCase();
    final result = places.where((place) {
      final favoriteMatches = !_showFavorites || favoriteIds.contains(place.id);
      final seasonMatches =
          season == null || place.bestSeason.toLowerCase().contains(season);
      final queryMatches =
          query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.region.toLowerCase().contains(query) ||
          place.description.toLowerCase().contains(query) ||
          place.bestSeason.toLowerCase().contains(query);
      final zoneMatches = _zone == null || zoneOf(place.region).id == _zone;
      return favoriteMatches && seasonMatches && queryMatches && zoneMatches;
    }).toList();
    return sortPlaces(result, _sort, ratings);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
      addUserPlace(newPlace); // жагсаалт + өгөгдлийн сан
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
      listenable: Listenable.merge([favorites, userRatings, trip, placeOrder]),
      builder: (context, _) {
        final visiblePlaces = _visiblePlaces(
          favorites.value,
          userRatings.value,
        );

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
                tooltip: 'Миний аялал',
                onPressed: () => context.push('/trip'),
                icon: Badge(
                  isLabelVisible: trip.active,
                  child: const Icon(Icons.luggage_outlined),
                ),
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
                                'Сайн байна уу, ${auth.displayName}!\nХаашаа аялах вэ?',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.onPrimaryContainer,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                trip.active
                                    ? 'Аялал: ${trip.route!.name} · '
                                          '${trip.doneCount}/${trip.route!.dayCount} өдөр'
                                    : 'Бэлэн маршрут сонгоод сүлжээгүй ч аялаарай.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.terrain_rounded,
                          size: 64,
                          color: colors.primary,
                        ),
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
                        _SortMenu(
                          value: _sort,
                          onChanged: (v) => setState(() {
                            _sort = v;
                            _reordering = false;
                          }),
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
                  const SizedBox(height: 4),
                  // Бүсийн шүүлтүүр: Баруун, Хангай, Төв, Зүүн, Улаанбаатар
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.public, size: 18),
                          label: const Text('Бүх бүс'),
                          selected: _zone == null,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _zone = null),
                        ),
                        for (final z in zones) ...[
                          const SizedBox(width: 6),
                          ChoiceChip(
                            avatar: Icon(z.icon, size: 18),
                            label: Text(z.name),
                            selected: _zone == z.id,
                            showCheckmark: false,
                            onSelected: (v) =>
                                setState(() => _zone = v ? z.id : null),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showFavorites ? 'Дуртай' : 'Газрууд',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${visiblePlaces.map((p) => zoneOf(p.region).id).toSet().length} бүс · '
                        '${visiblePlaces.length} газар',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      // «Миний дараалал»-ыг чирж засах горим
                      if (_sort == PlaceSort.custom) ...[
                        const SizedBox(width: 4),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () =>
                              setState(() => _reordering = !_reordering),
                          icon: Icon(
                            _reordering ? Icons.check : Icons.swap_vert,
                            size: 18,
                          ),
                          label: Text(_reordering ? 'Болсон' : 'Дараалал'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (visiblePlaces.isEmpty) {
                          return _EmptyState(
                            showingFavorites: _showFavorites,
                            filtered:
                                _query.trim().isNotEmpty ||
                                _season != null ||
                                _zone != null,
                          );
                        }
                        if (constraints.maxWidth >= 840) {
                          return _buildWideLayout(
                            context,
                            constraints.maxWidth,
                            visiblePlaces,
                          );
                        }
                        return _sort == PlaceSort.custom && _reordering
                            ? _buildReorderList(visiblePlaces)
                            : _buildZoneLayout(visiblePlaces);
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

  /// «Миний дараалал» засах: бариулаас чирж дарааллыг сольж, санд хадгална.
  Widget _buildReorderList(List<Place> items) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 92, top: 4),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      // onReorderItem: newIndex нь зөөгдсөн газрыг хассаны дараах байрлал
      onReorderItem: (oldIndex, newIndex) {
        reorderPlaces(
          [for (final p in sortPlaces(places, PlaceSort.custom)) p.id],
          [for (final p in items) p.id],
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final place = items[index];
        return PlaceListTile(
          key: ValueKey(place.id),
          place: place,
          onTap: null, // засах үед зөвхөн чирнэ
          highlighted: true,
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 20),
              child: Icon(Icons.drag_indicator),
            ),
          ),
        );
      },
    );
  }

  /// Газруудыг бүс → аймаг гэж хувааж харуулна. Бүсийн гарчиг дээр дарж
  /// хураана; газар дээр дарахад товч мэдээлэл гарна.
  Widget _buildZoneLayout(List<Place> items) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // бүс → аймаг → газрууд (эрэмбэ хадгалагдана)
    final grouped = <Zone, Map<String, List<Place>>>{};
    for (final p in items) {
      grouped
          .putIfAbsent(zoneOf(p.region), () => {})
          .putIfAbsent(aimagName(p.region), () => [])
          .add(p);
    }
    final order = [...zones, otherZone].where(grouped.containsKey);

    int aimagIndex(Zone z, String aimag) {
      final i = z.aimags.indexWhere((a) => aimag.contains(a));
      return i == -1 ? 99 : i;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 92, top: 4),
      children: [
        for (final zone in order) ...[
          () {
            final aimags = grouped[zone]!.keys.toList()
              ..sort(
                (a, b) => aimagIndex(zone, a).compareTo(aimagIndex(zone, b)),
              );
            final count = grouped[zone]!.values.fold(0, (s, l) => s + l.length);
            final collapsed = _collapsed.contains(zone.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: Icon(zone.icon),
                    ),
                    title: Text(
                      zone.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    subtitle: Text(
                      '${aimags.join(', ')} · $count газар',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onPrimaryContainer),
                    ),
                    trailing: Icon(
                      collapsed ? Icons.expand_more : Icons.expand_less,
                      color: colors.onPrimaryContainer,
                    ),
                    onTap: () => setState(() {
                      if (!_collapsed.remove(zone.id)) _collapsed.add(zone.id);
                    }),
                  ),
                ),
                if (!collapsed)
                  for (final aimag in aimags) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$aimag аймаг',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${grouped[zone]![aimag]!.length}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final place in grouped[zone]![aimag]!)
                      PlaceListTile(
                        key: ValueKey(place.id),
                        place: place,
                        onTap: () => showPlaceQuickView(context, place),
                        trailing: const Icon(Icons.chevron_right),
                        showRegion: false, // аймгийн гарчиг дээр бий
                      ),
                  ],
                const SizedBox(height: 12),
              ],
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    double width,
    List<Place> items,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected =
        items.where((p) => p.id == _selectedId).firstOrNull ?? items.first;

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
                  borderRadius: BorderRadius.circular(14),
                ),
                selected: place.id == selected.id,
                selectedTileColor: colors.secondaryContainer,
                leading: CircleAvatar(
                  foregroundImage: place.imageProvider,
                  onForegroundImageError: place.imageProvider == null
                      ? null
                      : (exception, stackTrace) {},
                  child: const Icon(Icons.landscape_outlined),
                ),
                title: Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Эрэмбийн сонголтын цэс.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onChanged});

  final PlaceSort value;
  final ValueChanged<PlaceSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlaceSort>(
      tooltip: 'Эрэмбэ солих',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final s in PlaceSort.values)
          PopupMenuItem(
            value: s,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                s == value
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(s.label),
              subtitle: Text(s.hint),
            ),
          ),
      ],
      child: Chip(
        avatar: const Icon(Icons.swap_vert, size: 18),
        label: Text('Эрэмбэ: ${value.label}'),
      ),
    );
  }
}
