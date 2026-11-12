// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/places.dart';
import 'models/place.dart';
import 'screens/add_place_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_picker_screen.dart';
import 'screens/places_map_screen.dart';
import 'screens/settings_screen.dart';
import 'state/auth_service.dart';

/// Апп-ын чиглүүлэлт. Нэвтрээгүй бол бүх хаяг `/login` руу шилжинэ;
/// `auth` өөрчлөгдөхөд (нэвтрэх, гарах) redirect дахин ажиллана.
final router = GoRouter(
  refreshListenable: auth,
  redirect: (context, state) {
    final atLogin = state.matchedLocation == '/login';
    if (!auth.loggedIn) return atLogin ? null : '/login';
    return atLogin ? '/' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/place/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final Place? place = places.where((p) => p.id == id).firstOrNull;
        if (place == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Газар олдсонгүй.')),
          );
        }
        return DetailScreen(place: place);
      },
    ),
    GoRoute(path: '/add', builder: (context, state) => const AddPlaceScreen()),
    GoRoute(
      path: '/map',
      builder: (context, state) {
        final extra = state.extra;
        return MapPickerScreen(
          args: extra is MapPickerArgs ? extra : const MapPickerArgs(),
        );
      },
    ),
    GoRoute(
      path: '/places-map',
      builder: (context, state) => const PlacesMapScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
  ],
);
