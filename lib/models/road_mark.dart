// lib/models/road_mark.dart
import 'package:flutter/material.dart';

/// Хэрэглэгчийн замд тавьсан тэмдэглэгээний төрөл.
enum RoadMarkType {
  badRoad('Бартаат зам', Icons.warning_amber_rounded, Colors.deepOrange),
  river('Гол гатлах', Icons.water, Colors.blue),
  checkpoint('Шалган нэвтрүүлэх', Icons.local_police_outlined, Colors.indigo),
  noSignal('Сүлжээгүй', Icons.signal_cellular_off, Colors.grey),
  view('Үзэсгэлэнт цэг', Icons.photo_camera_outlined, Colors.green),
  camp('Буудаллах газар', Icons.cabin_outlined, Colors.brown),
  note('Тэмдэглэл', Icons.push_pin_outlined, Colors.purple);

  const RoadMarkType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static RoadMarkType byName(String? name) =>
      values.where((t) => t.name == name).firstOrNull ?? note;
}

/// Маршрут дээр хэрэглэгчийн тэмдэглэсэн цэг (газрын зураг дээр удаан дарж
/// нэмнэ). Өгөгдлийн санд хадгалагдах тул сүлжээгүй үед ч харагдана.
class RoadMark {
  const RoadMark({
    required this.id,
    required this.routeId,
    required this.type,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final String routeId;
  final RoadMarkType type;
  final String note;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'routeId': routeId,
    'type': type.name,
    'note': note,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory RoadMark.fromMap(Map<dynamic, dynamic> m) => RoadMark(
    id: m['id'] as String,
    routeId: m['routeId'] as String,
    type: RoadMarkType.byName(m['type'] as String?),
    note: m['note'] as String? ?? '',
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (m['createdAt'] as num?)?.toInt() ?? 0,
    ),
  );
}
