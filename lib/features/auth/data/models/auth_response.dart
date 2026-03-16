class AuthResponse {
  final bool success;
  final String message;
  final String? messageCode;
  final String? phone;

  /// Access token (API returns as 'token')
  final String? accessToken;
  final String? refreshToken;
  final bool? isNewAccount;
  final String? fullName;
  final String? avatarUrl;

  AuthResponse({
    required this.success,
    required this.message,
    this.messageCode,
    this.phone,
    this.accessToken,
    this.refreshToken,
    this.isNewAccount,
    this.fullName,
    this.avatarUrl,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : (rawData is Map ? Map<String, dynamic>.from(rawData) : json);
    final rawAccount = data['account'];
    final account = rawAccount is Map<String, dynamic>
        ? rawAccount
        : (rawAccount is Map ? Map<String, dynamic>.from(rawAccount) : null);
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      messageCode: json['messageCode'] as String?,
      phone: data['phone'] as String?,
      // API returns 'token' for the access token
      accessToken: data['token'] as String? ?? data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
      isNewAccount: data['isNewAccount'] as bool?,
      fullName: account?['fullName'] as String?,
      avatarUrl: account?['avatarUrl'] as String?,
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
      if (fullName != null) 'fullName': fullName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
