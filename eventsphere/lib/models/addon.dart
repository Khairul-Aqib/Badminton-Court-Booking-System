class Addon {
  final int id;
  final String addonName;
  final String? description;
  final double price;

  Addon({
    required this.id,
    required this.addonName,
    this.description,
    required this.price,
  });

  factory Addon.fromMap(Map<String, dynamic> map) => Addon(
        id: map['id'],
        addonName: map['addon_name'] ?? '',
        description: map['description'],
        price: (map['price'] as num).toDouble(),
      );
}
