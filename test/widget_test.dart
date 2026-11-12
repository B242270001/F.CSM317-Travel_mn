import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_mn/data/places.dart';
import 'package:travel_mn/main.dart';
import 'package:travel_mn/models/place.dart';
import 'package:travel_mn/state/auth_service.dart';
import 'package:travel_mn/state/favorites.dart';
import 'package:travel_mn/state/ratings.dart';
import 'package:travel_mn/utils/geo.dart';
import 'package:travel_mn/utils/validators.dart';

void main() {
  test('Haversine: Улаанбаатараас Улаанбаатар 0 км, Хөвсгөл ~590 км', () {
    expect(distanceFromUbKm(ubLatitude, ubLongitude), 0);
    expect(distanceFromUbKm(51.05, 100.4833), inInclusiveRange(550, 650));
  });

  test('Үнэлгээ: (дундаж × тоо + миний од) / (тоо + 1)', () {
    const place = Place(
      id: 'p',
      name: 'n',
      region: 'r',
      image: '',
      description: 'd',
      rating: 4.0,
      ratingCount: 4,
      distanceKm: 0,
      bestSeason: 'Зун',
    );
    final summary = ratingOf(place, {'p': 5});
    expect(summary.count, 5);
    expect(summary.average, closeTo(4.2, 1e-9));
    expect(summary.mine, 5);

    // Шинэ газар (rating 0) — анхны үнэлгээ өөрөө дундаж болно
    const fresh = Place(
      id: 'f',
      name: 'n',
      region: 'r',
      image: '',
      description: 'd',
      rating: 0,
      distanceKm: 0,
      bestSeason: 'Зун',
    );
    expect(ratingOf(fresh, const {}).hasRating, isFalse);
    expect(ratingOf(fresh, {'f': 3}).average, 3);
  });

  test('Дуртай: нэмэх, хасах', () {
    toggleFavorite('x');
    expect(isFavorite('x'), isTrue);
    toggleFavorite('x');
    expect(isFavorite('x'), isFalse);
  });

  test('Нууц үг: шалгалт ба хүч', () {
    expect(validateNewPassword('abc12'), isNotNull); // богино
    expect(validateNewPassword('abcdefgh'), isNotNull); // тоогүй
    expect(validateNewPassword('12345678'), isNotNull); // үсэггүй
    expect(validateNewPassword('нууцүг123'), isNull); // кирилл үсэг
    expect(passwordStrength('abc'), PasswordStrength.weak);
    expect(passwordStrength('abcdefg1'), PasswordStrength.weak);
    expect(passwordStrength('Mobile317'), PasswordStrength.medium);
    expect(passwordStrength('Mobile317!xyz'), PasswordStrength.strong);
  });

  test('Нэвтрэх ба нууц үг солих', () async {
    final service = AuthService();
    expect(await service.login('a@b.mn', 'wrong-pass'), isFalse);
    expect(await service.login('a@b.mn', 'Mobile317'), isTrue);
    expect(await service.changePassword('wrong', 'Shine2026'), isFalse);
    expect(await service.changePassword('Mobile317', 'Shine2026'), isTrue);
    service.logout();
    expect(service.loggedIn, isFalse);
    expect(await service.login('a@b.mn', 'Shine2026'), isTrue);
  });

  test('10 газар бүгд координаттай', () {
    expect(places.length, 10);
    expect(places.every((p) => p.hasLocation), isTrue);
  });

  testWidgets('Нэвтрээгүй үед нэвтрэх дэлгэц, нэвтэрсний дараа нүүр дэлгэц',
      (tester) async {
    await tester.pumpWidget(const TravelApp());
    await tester.pumpAndSettle();
    expect(find.text('Нэвтрэх'), findsWidgets);
    expect(find.text('Газар нэмэх'), findsNothing);

    await tester.enterText(find.bySemanticsLabel('И-мэйл'), 'test@must.mn');
    await tester.enterText(find.bySemanticsLabel('Нууц үг'), 'Mobile317');
    await tester.tap(find.widgetWithText(FilledButton, 'Нэвтрэх'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Газар нэмэх'), findsOneWidget);
    expect(find.text('Үнэлгээгээр'), findsOneWidget);

    auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('Газар нэмэх'), findsNothing);
  });
}
