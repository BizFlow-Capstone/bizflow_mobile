import '../../../../shared/utils/date_formatter.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String?,
      createdAt: DateFormatter.parseApiDateTime(
        json['createdAt'] as String?,
        fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'createdAt': DateFormatter.toApiUtcIsoString(createdAt),
    };
  }
}
