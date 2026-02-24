/// Employee DTO - Data Transfer Object

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
    final data = json['data'] as Map<String, dynamic>?;
    final employeeList = data != null
        ? (data['employees'] as List<dynamic>? ?? [])
        : [];

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
  final String userId;
  final String userName;
  final String phone;

  EmployeeDto({required this.userId, required this.userName, this.phone = ''});

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    return EmployeeDto(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'userName': userName, 'phone': phone};
  }
}
