class AuthResponse {
  final bool success;
  final String message;
  final String? messageCode;
  final String? phone;
  /// Access token (API returns as 'token')
  final String? accessToken;
  final String? refreshToken;
  final bool? isNewAccount;

  AuthResponse({
    required this.success,
    required this.message,
    this.messageCode,
    this.phone,
    this.accessToken,
    this.refreshToken,
    this.isNewAccount,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      messageCode: json['messageCode'] as String?,
      phone: data['phone'] as String?,
      // API returns 'token' for the access token
      accessToken: data['token'] as String? ?? data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
      isNewAccount: data['isNewAccount'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (messageCode != null) 'messageCode': messageCode,
      if (phone != null) 'phone': phone,
      if (accessToken != null) 'token': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (isNewAccount != null) 'isNewAccount': isNewAccount,
    };
  }
}
