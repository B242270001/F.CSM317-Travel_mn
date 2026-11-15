// lib/models/poi.dart
import 'package:flutter/material.dart';

/// Зам дээрх үйлчилгээний цэгийн төрөл.
enum PoiType {
  fuel('Шатахуун', Icons.local_gas_station, Colors.orange),
  repair('Засвар', Icons.build, Colors.blueGrey),
  hospital('Эмнэлэг', Icons.local_hospital, Colors.red),
  shop('Дэлгүүр', Icons.storefront, Colors.teal);

  const PoiType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Маршрутын дагуух үйлчилгээний цэг.
class Poi {
  const Poi({
    required this.routeId,
    required this.type,
    required this.name,
    required this.place,
    required this.km,
    required this.latitude,
    required this.longitude,
  });

  final String routeId;
  final PoiType type;
  final String name;
  final String place; // сум, суурин
  final int km; // маршрутын эхлэлээс (УБ) тооцсон зай
  final double latitude;
  final double longitude;
}
