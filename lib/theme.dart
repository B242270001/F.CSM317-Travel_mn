// lib/theme.dart
import 'package:flutter/material.dart';

/// Апп-ын үндсэн өнгө. ColorScheme.fromSeed бүх өнгийг үүнээс үүсгэнэ.
const appSeed = Colors.teal;

/// Нэвтрэх, бүртгүүлэх дэлгэцийн брэндийн градиент.
///
/// Апп-ын үндсэн өнгө (teal)-ийн бараан → цайвар өнгөөр бүтнэ. Гэрэл,
/// харанхуй горимд хоёуланд нь ижил харагдаж, дээрх бичиг үргэлж цагаан байна
/// (colorScheme.primary нь харанхуй горимд цайвар болдог тул ашиглахгүй).
const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
  stops: [0.0, 0.55, 1.0],
);

/// Брэндийн градиент дээрх бичиг, дүрсний өнгө.
const brandForeground = Colors.white;
