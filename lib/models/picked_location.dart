// lib/models/picked_location.dart
import '../utils/geo.dart';

/// Газрын зургаас сонгосон байршил: координат ба хаягийн мэдээлэл.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
    this.region,
  });

  final double latitude;
  final double longitude;
  final String? address; // бүтэн хаяг, жишээ нь «Хатгал, Хөвсгөл, Монгол»
  final String? name; // газрын нэрийн санал (нуур, уул, сум ...)
  final String? region; // аймаг / хот

  PickedLocation copyWith({String? address, String? name, String? region}) =>
      PickedLocation(
        latitude: latitude,
        longitude: longitude,
        address: address ?? this.address,
        name: name ?? this.name,
        region: region ?? this.region,
      );

  String get coordinates => formatCoordinates(latitude, longitude);
}
