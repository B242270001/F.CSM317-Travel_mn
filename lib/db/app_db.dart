// lib/db/app_db.dart
import 'package:hive_flutter/hive_flutter.dart';

/// Төхөөрөмж дээрх локал өгөгдлийн сан (Hive — key/value NoSQL).
/// Android, iOS, вэб, Windows бүгд дээр ажиллана; интернэт шаардахгүй тул
/// апп сүлжээгүй үед ч хэрэглэгчийн өгөгдлийг уншиж, хадгална.
///
/// Хадгалах түлхүүрүүд:
/// • users          — бүртгэлтэй хэрэглэгчид: и-мэйл → {name, password}
/// • favorites      — дуртай газруудын id
/// • favoriteRoutes — дуртай маршрутуудын id
/// • ratings        — хэрэглэгчийн үнэлгээ: газрын id → 1–5 од
/// • userPlaces     — хэрэглэгчийн нэмсэн газрууд (зурагтайгаа)
/// • trip           — идэвхтэй аялал: маршрут, дууссан өдрүүд, жагсаалт
/// • offlineRegions — татсан бүсүүдийн id
/// • wifiOnly       — зөвхөн Wi-Fi-аар татах тохиргоо
/// • subscriptions  — Premium захиалга: и-мэйл → {plan, method, expires}
/// • roadMarks      — замын тэмдэглэгээ: [{routeId, type, note, lat, lng}]
/// • placeOrder     — газруудын хэрэглэгчийн өөрийн дараалал (id-ууд)
class AppDb {
  const AppDb._();

  static const _boxName = 'travel_mn';
  static Box<dynamic>? _box;

  static bool get isOpen => _box != null;

  /// Апп эхлэхэд нэг удаа дуудна.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  /// Тестэд: түр хавтсанд нээнэ.
  static Future<void> initForTest(String path) async {
    Hive.init(path);
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  static dynamic read(String key) => _box?.get(key);

  /// Сан нээгдээгүй бол (жишээ нь widget тест) чимээгүй алгасна.
  static Future<void> write(String key, dynamic value) async {
    await _box?.put(key, value);
  }

  static Future<void> delete(String key) async {
    await _box?.delete(key);
  }

  static List<String> readStrings(String key) =>
      (read(key) as List?)?.cast<String>() ?? const [];

  static Map<String, dynamic> readMap(String key) =>
      (read(key) as Map?)?.cast<String, dynamic>() ?? const {};
}
