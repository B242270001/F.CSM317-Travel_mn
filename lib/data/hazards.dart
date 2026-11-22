// lib/data/hazards.dart
import 'package:latlong2/latlong.dart';

import '../models/road_mark.dart';
import 'route_shapes.dart';

/// Маршрутад урьдчилан оруулсан замын анхааруулга (бартаат хэсэг, гол
/// гатлах газар г.м.). Хэрэглэгчийн тэмдэглэгээнээс ялгаатай нь апп-тай
/// хамт ирдэг тул бүх хэрэглэгчид ижил харагдана.
///
/// Байрлалыг координатаар биш, маршрутын [segment]-р хэсгийн замын хэлбэр
/// дээрх [fraction] (0–1) хувиар өгнө — ингэснээр цэг яг замын шугам дээр
/// буудаг. Мэдээлэл нь ойролцоо жишээ өгөгдөл.
class RoadHazard {
  const RoadHazard({
    required this.routeId,
    required this.segment,
    required this.fraction,
    required this.type,
    required this.title,
    required this.note,
  });

  final String routeId;
  final int segment;
  final double fraction;
  final RoadMarkType type;
  final String title;
  final String note;

  /// Замын шугам дээрх байрлал.
  LatLng get point {
    final flat = routeShapes[routeId]![segment];
    final count = flat.length ~/ 2;
    final i = (fraction.clamp(0.0, 1.0) * (count - 1)).round();
    return LatLng(flat[i * 2], flat[i * 2 + 1]);
  }
}

const roadHazards = <RoadHazard>[
  // Говийн адал явдал
  RoadHazard(
    routeId: 'gobi',
    segment: 2,
    fraction: 0.5,
    type: RoadMarkType.badRoad,
    title: 'Элс, хайрган бартаат зам',
    note:
        'Ёлын амаас Хонгорын элс хүртэл засмал байхгүй. Жийпээр, '
        'хамтдаа явах машинтай явна.',
  ),
  RoadHazard(
    routeId: 'gobi',
    segment: 3,
    fraction: 0.5,
    type: RoadMarkType.badRoad,
    title: 'Элсэн манхны хэсэг',
    note:
        'Хонгорын элсээс Баянзаг хүртэл элсэнд суух эрсдэлтэй. Дугуйн '
        'даралтаа бууруулж явна.',
  ),
  RoadHazard(
    routeId: 'gobi',
    segment: 4,
    fraction: 0.8,
    type: RoadMarkType.river,
    title: 'Онги гол гатлах',
    note: 'Зуны бороонд ус ихэсдэг. Гатлахаас өмнө гүнийг шалгана.',
  ),
  RoadHazard(
    routeId: 'gobi',
    segment: 1,
    fraction: 0.5,
    type: RoadMarkType.noSignal,
    title: 'Сүлжээгүй хэсэг',
    note: 'Утасны сүлжээ тасалддаг. Офлайн газрын зургаа урьдчилан татна.',
  ),
  // Төв Монголын алтан тойрог
  RoadHazard(
    routeId: 'central',
    segment: 3,
    fraction: 0.55,
    type: RoadMarkType.badRoad,
    title: 'Хад чулуутай бартаат зам',
    note:
        'Хархорин – Улаан цутгалан: хүрмэн чулуу, гүн нүхтэй. Удаан, '
        'болгоомжтой явна.',
  ),
  RoadHazard(
    routeId: 'central',
    segment: 3,
    fraction: 0.9,
    type: RoadMarkType.river,
    title: 'Орхон гол гатлах',
    note: 'Хүрхрээ орох замд Орхоны цутгал гатална. Зун ус ихэсдэг.',
  ),
  // Хөвсгөл далайн аялал
  RoadHazard(
    routeId: 'khuvsgul',
    segment: 3,
    fraction: 0.35,
    type: RoadMarkType.river,
    title: 'Эгийн гол гатлах',
    note: 'Гүүр, гатлагын байдлыг урьдчилан лавлана.',
  ),
  RoadHazard(
    routeId: 'khuvsgul',
    segment: 3,
    fraction: 0.6,
    type: RoadMarkType.badRoad,
    title: 'Шавартай шороон зам',
    note: 'Борооны дараа шаварт суух эрсдэлтэй.',
  ),
  // Тэрэлж
  RoadHazard(
    routeId: 'terelj',
    segment: 1,
    fraction: 0.5,
    type: RoadMarkType.badRoad,
    title: 'Нүх суваг ихтэй шороон зам',
    note: 'Тэрэлжээс хөшөө хүртэл удаан явна.',
  ),
  // Баруун хязгаарын экспедиц
  RoadHazard(
    routeId: 'west',
    segment: 6,
    fraction: 0.5,
    type: RoadMarkType.river,
    title: 'Цагаан гол гатлах',
    note: 'Зуны дунд мөсөн голын ус ихэсдэг. Өглөө эрт гатлах нь аюулгүй.',
  ),
  RoadHazard(
    routeId: 'west',
    segment: 6,
    fraction: 0.85,
    type: RoadMarkType.badRoad,
    title: 'Чулуурхаг уулын зам',
    note: 'Хотон нуур хүртэл зөвхөн өндөр явах эд ангитай машинаар.',
  ),
  RoadHazard(
    routeId: 'west',
    segment: 7,
    fraction: 0.3,
    type: RoadMarkType.checkpoint,
    title: 'Хилийн бүсийн шалган нэвтрүүлэх',
    note:
        'Алтай Таван Богдод орохдоо хилийн зөвшөөрөл, бичиг баримтаа шалгуулна.',
  ),
  // Чингисийн өлгий нутаг
  RoadHazard(
    routeId: 'east',
    segment: 1,
    fraction: 0.8,
    type: RoadMarkType.badRoad,
    title: 'Ойн шороон зам',
    note: 'Дадал хүрэх уулын зам борооны дараа шавартай, удаан явна.',
  ),
  RoadHazard(
    routeId: 'east',
    segment: 4,
    fraction: 0.9,
    type: RoadMarkType.checkpoint,
    title: 'Хилийн бүс',
    note:
        'Шилийн Богд хилийн бүсэд тул хилийн зөвшөөрөл, бичиг баримт авч явна.',
  ),
];

List<RoadHazard> hazardsOf(String routeId) =>
    roadHazards.where((h) => h.routeId == routeId).toList();
