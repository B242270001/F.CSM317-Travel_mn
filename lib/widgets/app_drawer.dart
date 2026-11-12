import 'package:flutter/material.dart';

import '../state/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onAllPlaces,
    required this.onFavorites,
    required this.onMap,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
    required this.showingFavorites,
  });

  final VoidCallback onAllPlaces;
  final VoidCallback onFavorites;
  final VoidCallback onMap;
  final VoidCallback onSettings;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final bool showingFavorites;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final email = auth.email;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colors.primaryContainer),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.travel_explore,
                      size: 38, color: colors.onPrimaryContainer),
                  const SizedBox(height: 10),
                  Text(
                    'TRAVEL MONGOLIA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                  ),
                  Text(
                    email ?? 'Монгол орноо нээцгээе',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Бүх газар'),
            selected: !showingFavorites,
            onTap: onAllPlaces,
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Дуртай газрууд'),
            selected: showingFavorites,
            onTap: onFavorites,
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Газрын зураг'),
            onTap: onMap,
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Тохиргоо'),
            onTap: onSettings,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Аппын тухай'),
            onTap: onAbout,
          ),
          const Divider(height: 24),
          ListTile(
            leading: Icon(Icons.logout, color: colors.error),
            title: Text('Гарах', style: TextStyle(color: colors.error)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
