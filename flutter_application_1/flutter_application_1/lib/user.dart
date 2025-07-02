class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final int isActive;
  final DateTime createdAt;
  final String? token; // این فیلد Nullable است

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.token, // این فیلد اختیاری است
  });

  // سازنده برای زمانی که کاربر لاگین می‌شود و توکن دارد
  factory User.fromLoginJson(Map<String, dynamic> json, String token) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json.containsKey('full_name') ? json['full_name'] : '',
      role: json['role'] ?? '',
      isActive: int.tryParse(json['is_active']?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      token: token,
    );
  }

  // سازنده برای لیست کاربران (بدون توکن)
  factory User.fromListJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json.containsKey('full_name') ? json['full_name'] : '',
      role: json['role'] ?? '',
      isActive: int.tryParse(json['is_active']?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      // token اینجا null می‌ماند
    );
  }
}
