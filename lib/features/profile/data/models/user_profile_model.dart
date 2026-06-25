class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.createdAt,
  });

  final int id;
  final String username;
  final String email;
  final DateTime? createdAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: _asInt(json['id']),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
