// lib/screens/main_shell.dart
import 'package:flutter/material.dart';

import 'favorites_screen.dart';
import 'home_screen.dart';
import 'places_map_screen.dart';
import 'routes_screen.dart';
import 'settings_screen.dart';

/// Доод цэстэй үндсэн бүтэц: Нүүр, Маршрут, Газрын зураг, Дуртай, Тохиргоо.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tabCount = 5;

  late int _index = widget.initialTab.clamp(0, _tabCount - 1);

  /// Нээж үзсэн табууд — газрын зураг зэрэг хүнд дэлгэцийг анх дарахад л үүсгэнэ.
  late final Set<int> _visited = {_index};

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `/?tab=1` гэх мэтээр гаднаас таб солих
    if (widget.initialTab != oldWidget.initialTab) _select(widget.initialTab);
  }

  void _select(int index) => setState(() {
    _index = index.clamp(0, _tabCount - 1);
    _visited.add(_index);
  });

  Widget _tab(int index) => switch (index) {
    0 => const HomeScreen(),
    1 => const RoutesScreen(),
    2 => const PlacesMapScreen(),
    3 => const FavoritesScreen(),
    _ => const SettingsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabCount; i++)
            _visited.contains(i) ? _tab(i) : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Нүүр',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Маршрут',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Зураг',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Дуртай',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Тохиргоо',
          ),
        ],
      ),
    );
  }
}
