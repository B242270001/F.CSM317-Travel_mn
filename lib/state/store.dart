// lib/state/store.dart
import '../data/places.dart';
import '../db/app_db.dart';
import '../models/place.dart';
import 'favorites.dart';
import 'offline.dart';
import 'ratings.dart';
import 'trip.dart';

/// Апп эхлэхэд өгөгдлийн сангаас бүх төлөвийг сэргээнэ.
void loadState() {
  favorites.value = AppDb.readStrings('favorites').toSet();
  favoriteRoutes.value = AppDb.readStrings('favoriteRoutes').toSet();
  userRatings.value = AppDb.readMap('ratings').cast<String, int>();
  offlineRegionIds.value = AppDb.readStrings('offlineRegions').toSet();
  wifiOnly.value = AppDb.read('wifiOnly') as bool? ?? true;
  trip.load();

  // Хэрэглэгчийн нэмсэн газруудыг жагсаалтын эхэнд сэргээнэ
  final saved = (AppDb.read('userPlaces') as List?) ?? const [];
  places.removeWhere((p) => p.id.startsWith('user-'));
  places.insertAll(0, saved.map((m) => Place.fromMap(m as Map)));
}

/// Хэрэглэгчийн нэмсэн газрыг жагсаалтад нэмж, өгөгдлийн санд хадгална.
void addUserPlace(Place place) {
  places.insert(0, place);
  AppDb.write('userPlaces', [
    for (final p in places)
      if (p.id.startsWith('user-')) p.toMap(),
  ]);
}
