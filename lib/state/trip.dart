// lib/state/trip.dart
import 'package:flutter/foundation.dart';

import '../data/routes.dart';
import '../db/app_db.dart';
import '../models/poi.dart';
import '../models/travel_route.dart';

/// «Миний аялал»: идэвхтэй маршрут, дууссан өдрүүд, авч явах зүйлсийн
/// жагсаалт. Өөрчлөлт бүрийг өгөгдлийн санд хадгална — сүлжээгүй ажиллана.
class TripState extends ChangeNotifier {
  String? _routeId;
  final Set<int> _doneDays = {};
  final Map<String, bool> _checklist = {};

  TravelRoute? get route => routeById(_routeId);
  bool get active => route != null;

  bool isDayDone(int index) => _doneDays.contains(index);
  int get doneCount => _doneDays.length;

  /// Дууссан өдрүүдийн нийт км.
  int get kmDone {
    final r = route;
    if (r == null) return 0;
    var sum = 0;
    for (final i in _doneDays) {
      if (i < r.days.length) sum += r.days[i].km;
    }
    return sum;
  }

  /// Явц 0–1.
  double get progress {
    final r = route;
    return r == null || r.days.isEmpty ? 0 : doneCount / r.dayCount;
  }

  /// Дараагийн дуусаагүй өдрийн индекс; бүгд дууссан бол null.
  int? get currentDay {
    final r = route;
    if (r == null) return null;
    for (var i = 0; i < r.dayCount; i++) {
      if (!_doneDays.contains(i)) return i;
    }
    return null;
  }

  /// Одоогийн байрлалаас (дараалсан дууссан өдрүүдийн төгсгөл) дараагийн
  /// шатахуун түгээх станц ба түүн хүртэлх зай.
  ({Poi poi, int kmAway})? get nextFuelStop {
    final r = route;
    if (r == null) return null;
    final at = r.kmAfterDays(currentDay ?? r.dayCount);
    final poi = nextFuel(r.id, at);
    return poi == null ? null : (poi: poi, kmAway: poi.km - at);
  }

  Map<String, bool> get checklist => Map.unmodifiable(_checklist);
  int get packedCount => _checklist.values.where((v) => v).length;

  void start(String routeId) {
    _routeId = routeId;
    _doneDays.clear();
    _checklist
      ..clear()
      ..addEntries(defaultChecklist.map((e) => MapEntry(e, false)));
    _changed();
  }

  void end() {
    _routeId = null;
    _doneDays.clear();
    _checklist.clear();
    _changed();
  }

  void toggleDay(int index) {
    if (!_doneDays.remove(index)) _doneDays.add(index);
    _changed();
  }

  void toggleItem(String item) {
    _checklist[item] = !(_checklist[item] ?? false);
    _changed();
  }

  /// Шинэ зүйл нэмнэ; хоосон эсвэл давхардсан бол false.
  bool addItem(String item) {
    final name = item.trim();
    if (name.isEmpty || _checklist.containsKey(name)) return false;
    _checklist[name] = false;
    _changed();
    return true;
  }

  void removeItem(String item) {
    if (_checklist.remove(item) != null) _changed();
  }

  void _changed() {
    notifyListeners();
    if (_routeId == null) {
      AppDb.delete('trip');
    } else {
      AppDb.write('trip', {
        'routeId': _routeId,
        'doneDays': _doneDays.toList(),
        'checklist': Map<String, bool>.of(_checklist),
      });
    }
  }

  /// Өгөгдлийн сангаас сэргээнэ.
  void load() {
    final m = AppDb.readMap('trip');
    _routeId = routeById(m['routeId'] as String?)?.id;
    _doneDays
      ..clear()
      ..addAll(((m['doneDays'] as List?) ?? const []).cast<int>());
    _checklist
      ..clear()
      ..addAll(((m['checklist'] as Map?) ?? const {}).cast<String, bool>());
    notifyListeners();
  }
}

/// Апп даяар ашиглах нэг TripState.
final trip = TripState();
