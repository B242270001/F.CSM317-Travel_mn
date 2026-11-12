// lib/utils/geo.dart
import 'dart:math';

/// Улаанбаатар (Сүхбаатарын талбай) — зай тооцох эхлэл цэг.
const ubLatitude = 47.9189;
const ubLongitude = 106.9176;

/// Хоёр цэгийн хоорондох шулуун зай (км) — Haversine томьёо.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Улаанбаатараас шулуун зай, бүхэл км.
int distanceFromUbKm(double lat, double lng) =>
    haversineKm(ubLatitude, ubLongitude, lat, lng).round();

String formatCoordinates(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
