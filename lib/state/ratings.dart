// lib/state/ratings.dart
import 'package:flutter/foundation.dart';

import '../models/place.dart';

/// Хэрэглэгчийн өгсөн үнэлгээ: газрын id → 1–5 од.
final userRatings = ValueNotifier<Map<String, int>>({});

void ratePlace(String placeId, int stars) {
  assert(stars >= 1 && stars <= 5);
  // Шинэ Map оноох нь чухал: байгаа map-ийг өөрчилбөл сонсогчдод мэдэгдэхгүй
  userRatings.value = {...userRatings.value, placeId: stars};
}

/// Газрын шинэчлэгдсэн дундаж үнэлгээ ба үнэлгээний тоо.
class RatingSummary {
  const RatingSummary(this.average, this.count, this.mine);

  final double average; // 0 = үнэлгээгүй
  final int count;
  final int? mine; // хэрэглэгчийн өөрийн үнэлгээ (байхгүй бол null)

  bool get hasRating => count > 0;
  String get label => average.toStringAsFixed(1);
}

/// Анхны дундаж дээр хэрэглэгчийн үнэлгээг нэмж шинэ дунджийг тооцно:
/// (дундаж × тоо + миний од) / (тоо + 1)
RatingSummary ratingOf(Place place, [Map<String, int>? ratings]) {
  final mine = (ratings ?? userRatings.value)[place.id];
  final baseCount = place.rating > 0 ? place.ratingCount : 0;
  if (mine == null) return RatingSummary(place.rating, baseCount, null);
  final count = baseCount + 1;
  final average = (place.rating * baseCount + mine) / count;
  return RatingSummary(average, count, mine);
}
