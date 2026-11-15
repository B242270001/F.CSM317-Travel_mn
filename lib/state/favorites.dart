// lib/state/favorites.dart
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';

/// Дуртай гэж тэмдэглэсэн газруудын id.
final favorites = ValueNotifier<Set<String>>({});

/// Дуртай гэж тэмдэглэсэн маршрутуудын id.
final favoriteRoutes = ValueNotifier<Set<String>>({});

bool isFavorite(String placeId) => favorites.value.contains(placeId);

/// Дуртайд нэмэх / хасах. Шинэ Set оноож байж сонсогчдод мэдэгдэнэ.
void toggleFavorite(String placeId) {
  final next = {...favorites.value};
  if (!next.remove(placeId)) next.add(placeId);
  favorites.value = next;
  AppDb.write('favorites', next.toList());
}

void toggleFavoriteRoute(String routeId) {
  final next = {...favoriteRoutes.value};
  if (!next.remove(routeId)) next.add(routeId);
  favoriteRoutes.value = next;
  AppDb.write('favoriteRoutes', next.toList());
}
