// lib/models/place.dart
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Монголын аяллын газрын мэдээллийн immutable model.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.region,
    required this.image,
    this.extraImages = const [],
    required this.description,
    required this.rating,
    this.ratingCount = 0,
    required this.distanceKm,
    required this.bestSeason,
    this.latitude,
    this.longitude,
    this.userImages = const [],
  });

  final String id;
  final String name;
  final String region;

  /// Үндсэн asset зураг ('assets/images/...'); хоосон бол asset зураггүй.
  final String image;

  /// Нэмэлт asset зургууд (дэлгэрэнгүй дэлгэцийн PageView-д).
  final List<String> extraImages;
  final String description;

  /// Анхны дундаж үнэлгээ 0–5; 0 = үнэлгээгүй.
  final double rating;

  /// Анхны үнэлгээний тоо.
  final int ratingCount;

  /// Улаанбаатараас тооцсон ойролцоо зай (км); 0 = тодорхойгүй.
  final int distanceKm;
  final String bestSeason;

  /// Өргөрөг, уртраг (газрын зургаас сонгосон).
  final double? latitude;
  final double? longitude;

  /// Хэрэглэгчийн оруулсан зургууд (3 хүртэл); хоосон бол asset ашиглана.
  final List<Uint8List> userImages;

  bool get hasLocation => latitude != null && longitude != null;

  /// Хэрэглэгчийн оруулсан эхний зураг (байхгүй бол null).
  Uint8List? get imageBytes => userImages.isEmpty ? null : userImages.first;

  /// Газрын бүх зураг: хэрэглэгч оруулсан бол тэдгээрийг, үгүй бол asset-уудыг.
  List<ImageProvider> get imageProviders => userImages.isNotEmpty
      ? [for (final bytes in userImages) MemoryImage(bytes)]
      : [
          if (image.isNotEmpty) AssetImage(image),
          for (final extra in extraImages) AssetImage(extra),
        ];

  /// Карт, жагсаалтад харуулах үндсэн зураг; зураггүй бол null.
  ImageProvider? get imageProvider {
    final all = imageProviders;
    return all.isEmpty ? null : all.first;
  }
}
