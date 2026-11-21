import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:travel_mn/data/places.dart';
import 'package:travel_mn/data/hazards.dart';
import 'package:travel_mn/data/route_shapes.dart';
import 'package:travel_mn/data/routes.dart';
import 'package:travel_mn/utils/geo.dart';
import 'package:travel_mn/widgets/route_map.dart';
import 'package:travel_mn/data/zones.dart';
import 'package:travel_mn/db/app_db.dart';
import 'package:travel_mn/models/road_mark.dart';
import 'package:travel_mn/models/travel_route.dart';
import 'package:travel_mn/state/place_order.dart';
import 'package:travel_mn/state/road_marks.dart';
import 'package:travel_mn/state/store.dart';
import 'package:travel_mn/state/subscription.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('travel_mn_saijruulalt');
    await AppDb.initForTest(dir.path);
  });

  tearDown(() async {
    await AppDb.close();
    await dir.delete(recursive: true);
  });

  test('Premium: худалдан авах, сунгах, дуусах, цуцлах', () async {
    final start = DateTime(2026, 11, 20);
    subscription.now = () => start;
    expect(subscription.isPremium, isFalse);

    await subscription.purchase(PremiumPlan.monthly, PaymentMethod.qpay);
    expect(subscription.isPremium, isTrue);
    expect(subscription.plan, PremiumPlan.monthly);
    expect(subscription.daysLeft, 30);

    // Идэвхтэй үед дахин төлбөл хугацаа сунгагдана
    await subscription.purchase(PremiumPlan.monthly, PaymentMethod.card);
    expect(subscription.expires, start.add(const Duration(days: 60)));

    // Хугацаа дуусвал Premium биш
    subscription.now = () => start.add(const Duration(days: 61));
    expect(subscription.isPremium, isFalse);

    subscription.now = () => start;
    await subscription.cancel();
    expect(subscription.isPremium, isFalse);
    subscription.now = DateTime.now;

    expect(formatPrice(79000), '79,000₮');
    expect(PremiumPlan.yearly.perMonth, lessThan(PremiumPlan.monthly.price));
    expect(travelRoutes.where((r) => r.premium).length, 2);
  });

  test('Бүс: аймгаас бүсийг олно', () {
    expect(zoneOf('Өмнөговь аймаг').id, 'central');
    expect(zoneOf('Төв аймаг').id, 'central');
    expect(zoneOf('Хөвсгөл аймаг').id, 'khangai');
    expect(zoneOf('Баян-Өлгий аймаг').id, 'west');
    expect(zoneOf('Хэнтий').id, 'east');
    expect(zoneOf('Тодорхойгүй газар').id, 'other');
    expect(aimagName('Өвөрхангай аймаг'), 'Өвөрхангай');
    // Жишээ газар бүр аль нэг бүсэд орно
    expect(places.every((p) => zoneOf(p.region) != otherZone), isTrue);
  });

  test('Бартаат зам: маршрутын хэсгүүд төрөлтэй', () {
    for (final r in travelRoutes) {
      expect(r.segments.length, r.stops.length - 1);
    }
    final gobi = routeById('gobi')!;
    expect(gobi.roughCount, 2);
    expect(gobi.segments[2].title, 'Ёлын ам → Хонгорын элс');
    expect(gobi.segments[2].type, RoadType.rough);
    expect(gobi.segments.last.type, RoadType.paved); // Мандалговь → УБ
    expect(routeById('terelj')!.roughCount, 0);

    // Хадгалсан замын хэлбэр хэсэг бүрт байгаа, зогсоолын ойролцоо эхэлж дуусна
    for (final r in travelRoutes) {
      final shapes = segmentPoints(r);
      expect(routeShapes[r.id]!.length, r.segments.length);
      for (var i = 0; i < shapes.length; i++) {
        expect(shapes[i].length, greaterThan(2));
        final from = r.segments[i].from;
        final to = r.segments[i].to;
        expect(
          haversineKm(
            from.latitude,
            from.longitude,
            shapes[i].first.latitude,
            shapes[i].first.longitude,
          ),
          lessThan(30),
        );
        expect(
          haversineKm(
            to.latitude,
            to.longitude,
            shapes[i].last.latitude,
            shapes[i].last.longitude,
          ),
          lessThan(30),
        );
      }
    }
  });

  test('Апп-ын анхааруулга: бартаат зам, гол гатлах зам дээр байрлана', () {
    expect(hazardsOf('gobi').any((h) => h.type == RoadMarkType.river), isTrue);
    expect(
      hazardsOf('central').any((h) => h.type == RoadMarkType.badRoad),
      isTrue,
    );
    for (final h in roadHazards) {
      final route = routeById(h.routeId)!;
      expect(h.segment, lessThan(route.segments.length));
      // Цэг тухайн хэсгийн замын хэлбэрийн цэгүүдийн нэг
      expect(segmentPoints(route)[h.segment], contains(h.point));
    }
  });

  test('Замын тэмдэглэгээ: нэмэх, сангаас сэргэх, устгах', () {
    final mark = addRoadMark(
      routeId: 'gobi',
      type: RoadMarkType.river,
      note: ' Гол үерлэсэн ',
      latitude: 44.5,
      longitude: 105.7,
    );
    addRoadMark(
      routeId: 'terelj',
      type: RoadMarkType.view,
      note: '',
      latitude: 47.9,
      longitude: 107.4,
    );
    expect(mark.note, 'Гол үерлэсэн');

    roadMarks.value = [];
    loadState(); // өгөгдлийн сангаас сэргээнэ
    final gobi = marksOf('gobi');
    expect(gobi.length, 1);
    expect(gobi.first.type, RoadMarkType.river);
    expect(gobi.first.latitude, 44.5);

    removeRoadMark(mark.id);
    loadState();
    expect(marksOf('gobi'), isEmpty);
    expect(marksOf('terelj').length, 1);
  });

  test('Эрэмбэ ба өөрийн дараалал (шүүлттэй үед ч)', () {
    placeOrder.value = [];
    final all = sortPlaces(places, PlaceSort.custom);
    expect(all.map((p) => p.id), places.map((p) => p.id));

    // Нэрээр, зайгаар
    final byName = sortPlaces(places, PlaceSort.name);
    expect(byName.first.name.compareTo(byName.last.name), lessThan(0));
    final byDistance = sortPlaces(places, PlaceSort.distance);
    expect(
      placeDistanceKm(byDistance.first),
      lessThanOrEqualTo(placeDistanceKm(byDistance.last)),
    );

    // Шүүгдсэн 3 газрын сүүлчийнхийг эхэнд зөөхөд бусад нь байрандаа
    final ids = [for (final p in all) p.id];
    final visible = [ids[1], ids[3], ids[5]];
    reorderPlaces(ids, visible, 2, 0);
    final next = [for (final p in sortPlaces(places, PlaceSort.custom)) p.id];
    expect(next[1], ids[5]);
    expect(next[3], ids[1]);
    expect(next[5], ids[3]);
    expect(next[0], ids[0]);
    expect(AppDb.readStrings('placeOrder'), next);
    placeOrder.value = [];
  });
}
