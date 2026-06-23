class Restaurant {
  final int id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: double.tryParse('${json['latitude'] ?? 0}') ?? 0.0,
      longitude: double.tryParse('${json['longitude'] ?? 0}') ?? 0.0,
    );
  }
}
