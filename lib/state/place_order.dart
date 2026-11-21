// lib/state/place_order.dart
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';
import '../models/place.dart';
import '../utils/geo.dart';
import 'ratings.dart';

/// Газруудын жагсаалтын эрэмбэ.
enum PlaceSort {
  custom('Миний дараалал', 'Чирж дарааллаа сольно'),
  name('Нэрээр', 'А → Я'),
  rating('Үнэлгээгээр', 'Өндрөөс нь'),
  distance('Ойроос нь', 'Улаанбаатараас');

  const PlaceSort(this.label, this.hint);

  final String label;
  final String hint;
}

/// Хэрэглэгчийн чирж тогтоосон дараалал (газрын id-ууд).
final placeOrder = ValueNotifier<List<String>>([]);

/// Газрын зай: хадгалсан утга, үгүй бол координатаас тооцно.
int placeDistanceKm(Place p) {
  if (p.distanceKm > 0) return p.distanceKm;
  if (p.hasLocation) return distanceFromUbKm(p.latitude!, p.longitude!);
  return 1 << 30; // тодорхойгүй бол хамгийн сүүлд
}

/// [items]-ийг сонгосон эрэмбээр шинэ жагсаалт болгон буцаана.
List<Place> sortPlaces(
  List<Place> items,
  PlaceSort sort, [
  Map<String, int>? ratings,
]) {
  final result = [...items];
  switch (sort) {
    case PlaceSort.custom:
      // Дараалалд байгаа нь эхэндээ, шинээр нэмэгдсэн нь анхны байрандаа
      final order = placeOrder.value;
      final index = {for (var i = 0; i < order.length; i++) order[i]: i};
      final original = {for (var i = 0; i < items.length; i++) items[i].id: i};
      int key(Place p) => index[p.id] ?? -1;
      result.sort((a, b) {
        final ka = key(a), kb = key(b);
        if (ka == -1 || kb == -1) {
          // дараалалд ороогүй (шинэ) газрууд дээрээ
          if (ka == kb) return original[a.id]!.compareTo(original[b.id]!);
          return ka == -1 ? -1 : 1;
        }
        return ka.compareTo(kb);
      });
    case PlaceSort.name:
      result.sort((a, b) => a.name.compareTo(b.name));
    case PlaceSort.rating:
      // Дундаж үнэлгээгээр буурахаар; тэнцвэл үнэлгээний тоогоор
      result.sort((a, b) {
        final ra = ratingOf(a, ratings);
        final rb = ratingOf(b, ratings);
        final byAverage = rb.average.compareTo(ra.average);
        return byAverage != 0 ? byAverage : rb.count.compareTo(ra.count);
      });
    case PlaceSort.distance:
      result.sort((a, b) => placeDistanceKm(a).compareTo(placeDistanceKm(b)));
  }
  return result;
}

/// Харагдаж буй (шүүгдсэн байж болох) жагсаалтад [oldIndex]-ийн газрыг
/// [newIndex] руу зөөнө. Шүүлтэд ороогүй газрууд байрандаа үлдэнэ.
/// [allSorted] — бүх газар одоогийн «Миний дараалал»-аар.
void reorderPlaces(
  List<String> allSorted,
  List<String> visible,
  int oldIndex,
  int newIndex,
) {
  final moved = [...visible];
  final id = moved.removeAt(oldIndex);
  moved.insert(newIndex.clamp(0, moved.length), id);
  final visibleSet = visible.toSet();
  var k = 0;
  final next = [
    for (final x in allSorted) visibleSet.contains(x) ? moved[k++] : x,
  ];
  placeOrder.value = next;
  AppDb.write('placeOrder', next);
}
