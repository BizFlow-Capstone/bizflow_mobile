class UserProfileResponse {
  final bool success;
  final String message;
  final String? fullName;
  final String? avatarUrl;
  final String? taxCode;

  UserProfileResponse({
    required this.success,
    required this.message,
    this.fullName,
    this.avatarUrl,
    this.taxCode,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : (rawData is Map ? Map<String, dynamic>.from(rawData) : json);

    return UserProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      fullName: data['fullName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      taxCode: data['taxCode'] as String?,
    );
  }
}
