class Court {
  final int id;
  final String courtName;
  final String? courtType;
  final double pricePerHour;
  final int capacity;
  final String? facilities;

  Court({
    required this.id,
    required this.courtName,
    this.courtType,
    required this.pricePerHour,
    this.capacity = 4,
    this.facilities,
  });

  factory Court.fromMap(Map<String, dynamic> map) => Court(
        id: map['id'],
        courtName: map['court_name'] ?? '',
        courtType: map['court_type'],
        pricePerHour: (map['price_per_hour'] as num).toDouble(),
        capacity: map['capacity'] ?? 4,
        facilities: map['facilities'],
      );
}
