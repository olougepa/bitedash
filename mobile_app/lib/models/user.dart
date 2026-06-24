class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String status;
  final int? cityId;
  final String? phone;

  User({required this.id, required this.email, required this.fullName, required this.role, this.status = 'active', this.cityId, this.phone});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse('${json['id']}') ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      status: json['status'] as String? ?? 'active',
      cityId: int.tryParse('${json['city_id']}') != -1 ? int.tryParse('${json['city_id']}') : null,
      phone: json['phone'] as String?,
    );
  }
}