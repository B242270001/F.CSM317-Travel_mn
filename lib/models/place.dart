/// Монголын аяллын газрын мэдээллийн immutable model.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.region,
    required this.image,
    required this.description,
    required this.rating,
    required this.distanceKm,
    required this.bestSeason,
  });

  final String id;
  final String name;
  final String region;
  final String image;
  final String description;
  final double rating;

  /// Улаанбаатараас тооцсон ойролцоо аяллын зай (км); маршрутаас шалтгаална.
  final int distanceKm;
  final String bestSeason;
}
