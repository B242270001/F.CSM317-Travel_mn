// lib/state/road_marks.dart
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';
import '../models/road_mark.dart';

/// Хэрэглэгчийн замд тавьсан бүх тэмдэглэгээ.
final roadMarks = ValueNotifier<List<RoadMark>>([]);

void loadRoadMarks() {
  final saved = (AppDb.read('roadMarks') as List?) ?? const [];
  roadMarks.value = [for (final m in saved) RoadMark.fromMap(m as Map)];
}

void _save() =>
    AppDb.write('roadMarks', [for (final m in roadMarks.value) m.toMap()]);

/// Тухайн маршрутын тэмдэглэгээнүүд, шинэ нь эхэндээ.
List<RoadMark> marksOf(String routeId) =>
    roadMarks.value.where((m) => m.routeId == routeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

RoadMark addRoadMark({
  required String routeId,
  required RoadMarkType type,
  required String note,
  required double latitude,
  required double longitude,
}) {
  final now = DateTime.now();
  final mark = RoadMark(
    id: 'mark-${now.microsecondsSinceEpoch}',
    routeId: routeId,
    type: type,
    note: note.trim(),
    latitude: latitude,
    longitude: longitude,
    createdAt: now,
  );
  roadMarks.value = [...roadMarks.value, mark];
  _save();
  return mark;
}

void removeRoadMark(String id) {
  roadMarks.value = roadMarks.value.where((m) => m.id != id).toList();
  _save();
}
