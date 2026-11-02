import 'package:flutter/material.dart';

import '../data/places.dart';
import '../models/place.dart';
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
  final Set<String> _favoriteIds = <String>{};
  late final List<Place> _places = List<Place>.of(places);

  String _query = '';
  bool _showFavorites = false;
  Place _selectedPlace = places.first;

  List<Place> get _visiblePlaces {
    final query = _query.trim().toLowerCase();
    return _places.where((place) {
      final favoriteMatches = !_showFavorites || _favoriteIds.contains(place.id);
      final queryMatches = query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.region.toLowerCase().contains(query) ||
          place.description.toLowerCase().contains(query) ||
          place.bestSeason.toLowerCase().contains(query);
      return favoriteMatches && queryMatches;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFavorite(Place place) {
    setState(() {
      if (_favoriteIds.contains(place.id)) {
        _favoriteIds.remove(place.id);
      } else {
        _favoriteIds.add(place.id);
      }
    });
  }

  void _openDetails(Place place) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          place: place,
          initialFavorite: _favoriteIds.contains(place.id),
          onFavoriteChanged: _toggleFavorite,
        ),
      ),
    );
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
          'зорилготой Flutter апп. StatelessWidget, Material 3, Row, Column, '
          'Expanded, Stack, GridView болон LayoutBuilder ашигласан.',
        ),
      ],
    );
  }

  Future<void> _showAddPlaceDialog() async {
    final nameController = TextEditingController();
    final regionController = TextEditingController();
    final descriptionController = TextEditingController();
    final distanceController = TextEditingController();

    final newPlace = await showDialog<Place>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Шинэ газар нэмэх'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Газрын нэр *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: regionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Аймаг / бүс *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Товч тайлбар *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'УБ-аас ойролцоо зай (км)',
                  hintText: 'Мэдэхгүй бол хоосон үлдээнэ',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Шинэ газар одоогоор жишээ зураг ашиглана.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final region = regionController.text.trim();
              final description = descriptionController.text.trim();
              final distance = int.tryParse(distanceController.text.trim()) ?? 0;
              if (name.isEmpty || region.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Одтой талбаруудыг бөглөнө үү.')),
                );
                return;
              }
              final id = 'custom-${DateTime.now().microsecondsSinceEpoch}';
              Navigator.of(dialogContext).pop(
                Place(
                  id: id,
                  name: name,
                  region: region,
                  image: 'assets/images/terelj.png',
                  description: description,
                  rating: 4.0,
                  distanceKm: distance < 0 ? 0 : distance,
                  bestSeason: 'Зун, намар',
                ),
              );
            },
            child: const Text('Нэмэх'),
          ),
        ],
      ),
    );

    nameController.dispose();
    regionController.dispose();
    descriptionController.dispose();
    distanceController.dispose();

    if (!mounted || newPlace == null) return;
    setState(() {
      _places.insert(0, newPlace);
      _selectedPlace = newPlace;
      _showFavorites = false;
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${newPlace.name}” жагсаалтад нэмэгдлээ.')),
    );
  }

  void _selectAllPlaces() {
    Navigator.of(context).pop();
    setState(() => _showFavorites = false);
  }

  void _selectFavorites() {
    Navigator.of(context).pop();
    setState(() => _showFavorites = true);
  }

  void _selectAbout() {
    Navigator.of(context).pop();
    _showAboutDialog();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visiblePlaces = _visiblePlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRAVEL MONGOLIA'),
        actions: [
          IconButton(
            tooltip: 'Хайх',
            onPressed: () => _searchFocusNode.requestFocus(),
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AppDrawer(
        showingFavorites: _showFavorites,
        onAllPlaces: _selectAllPlaces,
        onFavorites: _selectFavorites,
        onAbout: _selectAbout,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlaceDialog,
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
                    colors: [colors.primaryContainer, colors.secondaryContainer],
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
                    Icon(Icons.terrain_rounded, size: 64, color: colors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                    final matches = _visiblePlaces;
                    if (matches.isNotEmpty && !matches.any((p) => p.id == _selectedPlace.id)) {
                      _selectedPlace = matches.first;
                    }
                  });
                },
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _showFavorites ? 'Дуртай газрууд' : 'Байгалийн газрууд',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${visiblePlaces.length} газар',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 840) {
                      return _buildWideLayout(context, constraints.maxWidth, visiblePlaces);
                    }
                    return _buildGridLayout(context, constraints.maxWidth, visiblePlaces);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, double width, List<Place> items) {
    if (items.isEmpty) {
      return _EmptyState(showingFavorites: _showFavorites, query: _query);
    }
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
          place: place,
          isFavorite: _favoriteIds.contains(place.id),
          onFavoriteToggle: () => _toggleFavorite(place),
          onTap: () => _openDetails(place),
        );
      },
    );
  }

  Widget _buildWideLayout(BuildContext context, double width, List<Place> items) {
    if (items.isEmpty) {
      return _EmptyState(showingFavorites: _showFavorites, query: _query);
    }
    final selected = items.any((place) => place.id == _selectedPlace.id)
        ? _selectedPlace
        : items.first;

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
              final isSelected = place.id == selected.id;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                selected: isSelected,
                selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                leading: CircleAvatar(
                  backgroundImage: AssetImage(place.image),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: null,
                ),
                title: Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(place.region, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: _favoriteIds.contains(place.id)
                    ? Icon(Icons.favorite, size: 17, color: Theme.of(context).colorScheme.error)
                    : null,
                onTap: () => setState(() => _selectedPlace = place),
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
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: PlaceDetailView(
                place: selected,
                isFavorite: _favoriteIds.contains(selected.id),
                onFavoriteToggle: () => _toggleFavorite(selected),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showingFavorites, required this.query});

  final bool showingFavorites;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
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
              query.isNotEmpty
                  ? 'Таны хайлтад тохирох газар олдсонгүй.'
                  : 'Одоогоор дуртай газар алга.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              query.isNotEmpty
                  ? 'Өөр нэр, аймаг эсвэл улирлаар хайж үзээрэй.'
                  : 'Карт дээрх зүрхэн товчийг дарж дуртай газраа хадгална уу.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
