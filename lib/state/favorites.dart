// lib/state/favorites.dart
import 'package:flutter/foundation.dart';

/// Дуртай гэж тэмдэглэсэн газруудын id.
final favorites = ValueNotifier<Set<String>>({});

bool isFavorite(String placeId) => favorites.value.contains(placeId);

/// Дуртайд нэмэх / хасах. Шинэ Set оноож байж сонсогчдод мэдэгдэнэ.
void toggleFavorite(String placeId) {
  final next = {...favorites.value};
  if (!next.remove(placeId)) next.add(placeId);
  favorites.value = next;
}
