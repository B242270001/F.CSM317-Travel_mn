// lib/config.dart
import 'package:flutter/foundation.dart';

/// OpenStreetMap-ийн ашиглах нөхцлийн дагуу хүсэлт бүрт апп-аа танилцуулна.
const appPackageName = 'com.example.travel_mn';

/// Nominatim-д илгээх User-Agent. Үүнгүйгээр (эсвэл Dart-ын өгөгдмөл
/// User-Agent-аар) хүсэлт 403 алдаагаар хаагдаж болно.
const nominatimUserAgent = 'travel_mn/1.3 (Flutter lab app; $appPackageName)';

/// Газар нэмэх формд нэг газарт оруулах зургийн дээд тоо.
const maxPlaceImages = 3;

/// Камераар зураг авах боломж (утас, таблет).
bool get cameraSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
