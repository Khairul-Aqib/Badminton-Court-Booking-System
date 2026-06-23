class Booking {
  final int? id;
  final int userId;
  final int courtId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double durationHours;
  final double basePrice;
  final double addonsTotal;
  final double totalAmount;
  final String status;
  final String? bookedAt;

  // Joined fields from Supabase
  final String? courtName;
  final String? courtType;
  final List<Map<String, dynamic>> addons;

  Booking({
    this.id,
    required this.userId,
    required this.courtId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.basePrice,
    this.addonsTotal = 0,
    required this.totalAmount,
    this.status = 'confirmed',
    this.bookedAt,
    this.courtName,
    this.courtType,
    this.addons = const [],
  });

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'court_id': courtId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
        'duration_hours': durationHours,
        'base_price': basePrice,
        'addons_total': addonsTotal,
        'total_amount': totalAmount,
        'status': status,
      };

  factory Booking.fromMap(Map<String, dynamic> map) {
    final courts = map['courts'];
    final addonsList = map['booking_addons'];
    return Booking(
      id: map['id'],
      userId: map['user_id'],
      courtId: map['court_id'],
      bookingDate: map['booking_date']?.toString() ?? '',
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      durationHours: (map['duration_hours'] as num?)?.toDouble() ?? 0,
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 0,
      addonsTotal: (map['addons_total'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'confirmed',
      bookedAt: map['booked_at']?.toString(),
      courtName: courts != null ? courts['court_name'] : null,
      courtType: courts != null ? courts['court_type'] : null,
      addons: addonsList != null
          ? List<Map<String, dynamic>>.from(addonsList)
          : [],
    );
  }
}
