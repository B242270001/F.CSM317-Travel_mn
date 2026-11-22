import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:travel_mn/data/places.dart';
import 'package:travel_mn/data/routes.dart';
import 'package:travel_mn/data/zones.dart';
import 'package:travel_mn/db/app_db.dart';
import 'package:travel_mn/models/place.dart';
import 'package:travel_mn/models/poi.dart';
import 'package:travel_mn/state/auth_service.dart';
import 'package:travel_mn/state/favorites.dart';
import 'package:travel_mn/state/offline.dart';
import 'package:travel_mn/state/ratings.dart';
import 'package:travel_mn/state/store.dart';
import 'package:travel_mn/state/trip.dart';
import 'package:travel_mn/widgets/route_card.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('travel_mn_test');
    await AppDb.initForTest(dir.path);
  });

  tearDown(() async {
    await AppDb.close();
    await dir.delete(recursive: true);
  });

  test('Маршрутын өгөгдөл: км, зогсоол, бүс, зам дээрх цэг', () {
    expect(travelRoutes.length, 6);
    final gobi = routeById('gobi')!;
    expect(gobi.dayCount, 7);
    expect(gobi.totalKm, 1850);
    expect(gobi.stopCount, 6);
    expect(gobi.kmAfterDays(2), 660);
    for (final r in travelRoutes) {
      // Маршрут бүр УБ-аас эхэлж УБ-д дуусна, бүс нь жагсаалтад бий
      expect(r.stops.first.name, 'УБ');
      expect(r.stops.last.name, 'УБ');
      expect(offlineRegions.any((o) => o.id == r.region), isTrue);
      // Зам дээрх цэг маршрутын уртаас хэтрэхгүй, шатахуунтай
      final pois = poisOf(r.id);
      expect(pois.any((p) => p.type == PoiType.fuel), isTrue);
      expect(pois.every((p) => p.km <= r.totalKm), isTrue);
    }
    expect(formatKm(1850), '1,850');
    expect(formatCost(1400000), '1.4 сая₮');
    expect(formatCost(850000), '850 мянга₮');
  });

  test('Маршрутын зогсоол газартай холбогдоно', () {
    String? linked(String routeId, String stop) {
      final s = routeById(routeId)!.stops.firstWhere((x) => x.name == stop);
      return placeNear(s.latitude, s.longitude)?.id;
    }

    expect(linked('gobi', 'Баянзаг'), 'bayanzag');
    expect(linked('gobi', 'Онгийн хийд'), 'ongi');
    expect(linked('central', 'Хархорин'), 'erdene-zuu');
    expect(linked('khuvsgul', 'Хатгал'), 'khatgal');
    // 14 км зайтай Тэрэлжийг биш, хөшөөг өөрийг нь нээнэ
    expect(linked('terelj', 'Чингисийн хөшөө'), 'chinggis-statue');
    expect(linked('west', 'Хархорин'), 'erdene-zuu');
    expect(linked('east', 'Хөх нуур'), 'khukh-nuur');
    expect(linked('east', 'Дадал'), 'deluun-boldog');
    expect(linked('east', 'Шилийн Богд'), 'shiliin-bogd');
    expect(linked('east', 'Чойбалсан'), isNull);
    expect(linked('west', 'Тэрхийн цагаан нуур'), 'khorgo');
    // Хот, сум бол газар биш
    expect(linked('gobi', 'Мандалговь'), isNull);
  });

  test('Зүүн бүс: маршрут, газрууд, офлайн бүс', () {
    final east = routeById('east')!;
    expect(east.dayCount, 8);
    expect(east.totalKm, 2305);
    expect(east.premium, isFalse);
    expect(offlineRegions.any((o) => o.id == 'east'), isTrue);
    expect(places.where((p) => zoneOf(p.region).id == 'east').length, 7);
    // Чингис хотоос (405 км) Дадал хүртэл 258 км шатахуунгүй — сэрэмжлүүлнэ
    expect(nextFuel('east', 405)!.place, 'Дадал');
    expect(nextFuel('east', 405)!.km - 405, greaterThan(200));
  });

  test('Баруун хязгаарын маршрут: км, зогсоол, шатахуун', () {
    final west = routeById('west')!;
    expect(west.dayCount, 13);
    expect(west.totalKm, 4005);
    expect(west.stopCount, 11);
    expect(west.region, 'west');
    // Цэнгэлээс (1970 км) дараагийн шатахуун буцах замд Өлгийд — 325 км,
    // тиймээс Хотон нуур руу явахаас өмнө сэрэмжлүүлнэ
    expect(nextFuel('west', 1970)!.place, 'Өлгий');
    expect(nextFuel('west', 1970)!.km - 1970, greaterThan(200));
  });

  test('Дараагийн шатахуун: явцаас хамаарч өөрчлөгдөнө', () {
    expect(nextFuel('gobi', 0)!.place, 'Мандалговь');
    expect(nextFuel('gobi', 300)!.place, 'Даланзадгад');
    expect(nextFuel('gobi', 1840), isNull);
  });

  test('Миний аялал: явц, жагсаалт, өгөгдлийн санд хадгалалт', () {
    trip.start('gobi');
    expect(trip.active, isTrue);
    expect(trip.currentDay, 0);
    expect(trip.nextFuelStop!.kmAway, 270);

    trip.toggleDay(0);
    trip.toggleDay(1);
    expect(trip.doneCount, 2);
    expect(trip.kmDone, 660);
    expect(trip.currentDay, 2);
    expect(trip.progress, closeTo(2 / 7, 1e-9));
    // 660 км-ээс хойших эхний шатахуун: Булган сум (1000 км)
    expect(trip.nextFuelStop!.poi.place, 'Булган сум');
    expect(trip.nextFuelStop!.kmAway, 340);

    expect(trip.addItem('Дуран'), isTrue);
    expect(trip.addItem('Дуран'), isFalse); // давхардал
    expect(trip.addItem('  '), isFalse);
    trip.toggleItem('Дуран');
    expect(trip.packedCount, 1);

    // Шинэ TripState сангаас сэргээнэ
    final restored = TripState()..load();
    expect(restored.route!.id, 'gobi');
    expect(restored.doneCount, 2);
    expect(restored.checklist['Дуран'], isTrue);

    trip.end();
    expect((TripState()..load()).active, isFalse);
  });

  test(
    'Миний аялал: хол өдрийг тэмдэглэхэд өмнөх өдрүүд, км хуримтлагдана',
    () {
      trip.start('gobi');
      final gobi = routeById('gobi')!;
      // 6-р өдрийг (Онгийн хийд → Мандалговь) шууд тэмдэглэнэ
      trip.toggleDay(5);
      expect(trip.doneCount, 6);
      expect(trip.kmDone, gobi.kmAfterDays(6)); // УБ-аас хуримтлагдсан км
      expect(trip.kmDone, 1580);
      expect(trip.currentDay, 6);
      // 3-р өдрийг арилгавал түүнээс хойших өдрүүд мөн арилна
      trip.toggleDay(2);
      expect(trip.doneCount, 2);
      expect(trip.kmDone, 660);
      // Тасархай хадгалсан хуучин өгөгдлийг дараалал болгож сэргээнэ
      AppDb.write('trip', {
        'routeId': 'gobi',
        'doneDays': [0, 3],
        'checklist': <String, bool>{},
      });
      final restored = TripState()..load();
      expect(restored.doneCount, 4);
      expect(restored.kmDone, 1040);
      trip.end();
    },
  );

  test('Дуртай, үнэлгээ, офлайн бүс, нэмсэн газар сангаас сэргэнэ', () {
    toggleFavorite('terelj');
    toggleFavoriteRoute('gobi');
    ratePlace('terelj', 5);
    setRegionOffline('gobi', true);
    setWifiOnly(false);
    addUserPlace(
      Place(
        id: 'user-1',
        name: 'Шинэ газар',
        region: 'Төв аймаг',
        image: '',
        description: 'Туршилтын газар',
        rating: 0,
        distanceKm: 12,
        bestSeason: 'Зун',
        latitude: 47.5,
        longitude: 106.5,
        userImages: [
          Uint8List.fromList([1, 2, 3]),
        ],
      ),
    );

    // Санах ойн төлөвийг цэвэрлээд сангаас дахин уншина
    favorites.value = {};
    favoriteRoutes.value = {};
    userRatings.value = {};
    offlineRegionIds.value = {};
    wifiOnly.value = true;
    places.removeWhere((p) => p.id.startsWith('user-'));
    loadState();

    expect(isFavorite('terelj'), isTrue);
    expect(favoriteRoutes.value, {'gobi'});
    expect(userRatings.value['terelj'], 5);
    expect(isRegionOffline('gobi'), isTrue);
    expect(wifiOnly.value, isFalse);
    final saved = places.first;
    expect(saved.id, 'user-1');
    expect(saved.distanceKm, 12);
    expect(saved.hasLocation, isTrue);
    expect(saved.userImages.single, [1, 2, 3]);

    places.removeWhere((p) => p.id.startsWith('user-'));
  });

  test('Бүртгүүлэх, нэвтрэх, нууц үг солих', () async {
    final service = AuthService();
    expect(await service.register('Бат', 'bat@must.mn', 'Nuuts123'), isNull);
    expect(service.loggedIn, isTrue);
    expect(service.displayName, 'Бат');
    // Давхар бүртгэл
    expect(await service.register('Бат', 'BAT@must.mn', 'Nuuts123'), isNotNull);

    service.logout();
    // Бүртгэлтэй хэрэглэгч анхны (зочин) нууц үгээр нэвтэрч чадахгүй
    expect(await service.login('bat@must.mn', 'Mobile317'), isFalse);
    expect(await service.login('bat@must.mn', 'Nuuts123'), isTrue);
    expect(await service.changePassword('buruu', 'Shine2026'), isFalse);
    expect(await service.changePassword('Nuuts123', 'Shine2026'), isTrue);

    // Шинэ AuthService (апп дахин эхэлсэн) — нууц үг санд хадгалагдсан
    final again = AuthService();
    expect(await again.login('bat@must.mn', 'Nuuts123'), isFalse);
    expect(await again.login('bat@must.mn', 'Shine2026'), isTrue);
    // Бүртгэлгүй и-мэйл зочноор нэвтэрнэ
    expect(await again.login('zochin@must.mn', 'Mobile317'), isTrue);
  });
}
