class Itinerary {
  final String id;
  final String title;
  final List<String> destinations;
  final String startDate;
  final String endDate;
  final String notes;

  Itinerary({
    required this.id,
    required this.title,
    required this.destinations,
    required this.startDate,
    required this.endDate,
    required this.notes,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      destinations: List<String>.from(json['destinations'] as List? ?? []),
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}
