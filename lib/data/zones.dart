// lib/data/zones.dart
import 'package:flutter/material.dart';

/// Монгол Улсын бүс (эдийн засгийн 5 бүсийн хуваарь) ба харьяа аймгууд.
class Zone {
  const Zone(this.id, this.name, this.icon, this.aimags);

  final String id;
  final String name;
  final IconData icon;

  /// «аймаг» үггүй аймгийн нэрс.
  final List<String> aimags;
}

const zones = [
  Zone('west', 'Баруун бүс', Icons.landscape, [
    'Баян-Өлгий',
    'Говь-Алтай',
    'Завхан',
    'Увс',
    'Ховд',
  ]),
  Zone('khangai', 'Хангайн бүс', Icons.forest, [
    'Архангай',
    'Баянхонгор',
    'Булган',
    'Орхон',
    'Өвөрхангай',
    'Хөвсгөл',
  ]),
  Zone('central', 'Төвийн бүс', Icons.terrain, [
    'Говьсүмбэр',
    'Дархан-Уул',
    'Дорноговь',
    'Дундговь',
    'Өмнөговь',
    'Сэлэнгэ',
    'Төв',
  ]),
  Zone('east', 'Зүүн бүс', Icons.grass, ['Дорнод', 'Сүхбаатар', 'Хэнтий']),
  Zone('ub', 'Улаанбаатар', Icons.location_city, ['Улаанбаатар']),
];

/// Аль ч бүсэд таарахгүй (хэрэглэгчийн чөлөөт бичвэр) газрууд.
const otherZone = Zone('other', 'Бусад', Icons.place, []);

/// Газрын аймгаас бүсийг олно. «Төв» нь «Дундговь»-той андуурагдахгүйн тулд
/// урт нэрээс нь эхэлж шалгана.
Zone zoneOf(String region) {
  String? best;
  Zone? found;
  for (final z in zones) {
    for (final a in z.aimags) {
      if (region.toLowerCase().contains(a.toLowerCase()) &&
          (best == null || a.length > best.length)) {
        best = a;
        found = z;
      }
    }
  }
  return found ?? otherZone;
}

/// «Өмнөговь аймаг» → «Өмнөговь».
String aimagName(String region) =>
    region.replaceAll(RegExp(r'\s*аймаг\s*$'), '').trim();
