class AuthResponse {
  final bool success;
  final String message;
  final String? phone;
  final String? token;
  final String? refreshToken;

  AuthResponse({
    required this.success,
    required this.message,
    this.phone,
    this.token,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      phone: json['phone'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (phone != null) 'phone': phone,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }
}
