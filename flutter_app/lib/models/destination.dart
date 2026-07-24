class Destination {
  final String name;
  final String country;
  final String description;
  final List<String> tags;
  final String continent;
  final int avgCostPerDay;
  final double latitude;
  final double longitude;
  final String imageUrl;

  Destination({
    required this.name,
    required this.country,
    required this.description,
    required this.tags,
    required this.continent,
    required this.avgCostPerDay,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['name'] as String,
      country: json['country'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags'] as List<dynamic>),
      continent: json['continent'] as String,
      avgCostPerDay: json['avg_cost_per_day'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}
