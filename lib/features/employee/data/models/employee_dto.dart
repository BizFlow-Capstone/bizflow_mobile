/// Employee DTO - Data Transfer Object
library;

/// Employee Response from API
class EmployeeResponseDto {
  final List<EmployeeDto> employees;
  final bool success;
  final String messageCode;
  final String message;
  final String timestamp;

  EmployeeResponseDto({
    required this.employees,
    required this.success,
    required this.messageCode,
    required this.message,
    required this.timestamp,
  });

  factory EmployeeResponseDto.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final employeeList = switch (rawData) {
      List<dynamic> list => list,
      Map<String, dynamic> map => (map['employees'] as List<dynamic>? ?? []),
      _ => <dynamic>[],
    };

    return EmployeeResponseDto(
      employees: employeeList
          .map((item) => EmployeeDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      success: json['success'] as bool? ?? false,
      messageCode: json['messageCode'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

/// Single Employee DTO
class EmployeeDto {
  final String profileId;
  final String userName;
  final String phone;
  final String email;
  final String? avatarUrl;
  final bool isAlreadyHired;

  EmployeeDto({
    required this.profileId,
    required this.userName,
    this.phone = '',
    this.email = '',
    this.avatarUrl,
    this.isAlreadyHired = false,
  });

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    return EmployeeDto(
      profileId: json['profileId'] as String? ?? json['userId'] as String? ?? '',
      userName:
          json['userName'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isAlreadyHired: json['isAlreadyHired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'userName': userName,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'isAlreadyHired': isAlreadyHired,
    };
  }
}
