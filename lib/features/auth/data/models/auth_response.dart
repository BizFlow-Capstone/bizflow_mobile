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
  final bool? hasPassword;
  final List<String> credentialTypes;

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
    this.hasPassword,
    this.credentialTypes = const <String>[],
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

    final rawCredentials = account?['credentials'];
    final credentials = rawCredentials is List
        ? rawCredentials
        : const <dynamic>[];

    String? normalizeCredentialType(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim().toLowerCase();
      if (text.isEmpty) return null;
      if (text.contains('phone')) return 'phone';
      if (text.contains('email')) return 'email';
      if (text.contains('google')) return 'google';
      return null;
    }

    final normalizedCredentialTypes = credentials
        .map((item) {
          if (item is String) {
            return normalizeCredentialType(item);
          }
          if (item is Map<String, dynamic>) {
            return normalizeCredentialType(
              item['type'] ??
                  item['credentialType'] ??
                  item['provider'] ??
                  item['method'],
            );
          }
          if (item is Map) {
            return normalizeCredentialType(
              item['type'] ??
                  item['credentialType'] ??
                  item['provider'] ??
                  item['method'],
            );
          }
          return null;
        })
        .whereType<String>()
        .toSet()
        .toList();

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
      hasPassword: account?['hasPassword'] as bool?,
      credentialTypes: normalizedCredentialTypes,
    );
  }

  bool get hasPhoneCredential => credentialTypes.contains('phone');

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
      if (hasPassword != null) 'hasPassword': hasPassword,
      if (credentialTypes.isNotEmpty) 'credentialTypes': credentialTypes,
    };
  }
}
