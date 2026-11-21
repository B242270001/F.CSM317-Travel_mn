// lib/state/subscription.dart
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';
import 'auth_service.dart';

/// Premium захиалгын багц.
enum PremiumPlan {
  monthly('Сарын', 9900, 30),
  yearly('Жилийн', 79000, 365);

  const PremiumPlan(this.label, this.price, this.days);

  final String label;
  final int price; // ₮
  final int days;

  /// Сард ногдох үнэ (жилийн багцын хэмнэлтийг харуулахад).
  int get perMonth => (price / days * 30).round();

  static PremiumPlan? byName(String? name) =>
      values.where((p) => p.name == name).firstOrNull;
}

/// Төлбөрийн хэрэгсэл (сургалтын хувилбарт дуурайлгасан).
enum PaymentMethod {
  qpay('QPay'),
  socialPay('SocialPay'),
  card('Банкны карт');

  const PaymentMethod(this.label);

  final String label;
}

/// Free хэрэглэгчийн хязгаар.
const freeOfflineRegions = 1; // офлайнд татах бүс
const freeRoadMarksPerRoute = 3; // маршрут бүрт замын тэмдэглэгээ

/// 9900 → «9,900₮»
String formatPrice(int tugrug) =>
    '${tugrug.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}₮';

/// Хэрэглэгч бүрийн Premium захиалга. Өгөгдлийн санд
/// `subscriptions` түлхүүрээр и-мэйл → {plan, expires, method} хэлбэрээр
/// хадгалагдана. Нэвтэрсэн хэрэглэгч солигдоход дахин мэдэгдэнэ.
///
/// Анхаар: сургалтын апп тул төлбөрийг дуурайлгасан — бодит мөнгө
/// шилжүүлэхгүй. Бодит хувилбарт QPay/банкны API-г сервер талд холбоно.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService() {
    auth.addListener(notifyListeners);
  }

  /// Тестэд цагийг солих боломжтой.
  DateTime Function() now = DateTime.now;

  String get _key => auth.email?.toLowerCase() ?? 'guest';

  Map<String, dynamic> get _all => AppDb.readMap('subscriptions');

  Map<String, dynamic>? get _mine =>
      (_all[_key] as Map?)?.cast<String, dynamic>();

  PremiumPlan? get plan => PremiumPlan.byName(_mine?['plan'] as String?);

  DateTime? get expires {
    final ms = (_mine?['expires'] as num?)?.toInt();
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get isPremium {
    final e = expires;
    return e != null && e.isAfter(now());
  }

  /// Дуусахад үлдсэн өдөр, дээш тоймлосон (Premium биш бол 0).
  int get daysLeft =>
      isPremium ? (expires!.difference(now()).inHours + 23) ~/ 24 : 0;

  /// Төлбөр төлж Premium идэвхжүүлнэ. Идэвхтэй бол хугацааг сунгана.
  Future<void> purchase(PremiumPlan plan, PaymentMethod method) async {
    // төлбөрийн сервертэй холбогдохыг дуурайлгана
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final start = isPremium ? expires! : now();
    await AppDb.write('subscriptions', {
      ..._all,
      _key: {
        'plan': plan.name,
        'method': method.name,
        'expires': start.add(Duration(days: plan.days)).millisecondsSinceEpoch,
      },
    });
    notifyListeners();
  }

  /// Захиалгыг цуцална.
  Future<void> cancel() async {
    await AppDb.write('subscriptions', {..._all}..remove(_key));
    notifyListeners();
  }
}

/// Апп даяар ашиглах нэг захиалгын үйлчилгээ.
final subscription = SubscriptionService();
