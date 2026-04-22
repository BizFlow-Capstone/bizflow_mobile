/// Employee DTO - Data Transfer Object
library;

import '../../../../core/reference/data/reference_item.dart';
import '../../../../shared/utils/date_formatter.dart';

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
  final bool isActive;
  final String status;
  final String? statusLabel;
  final DateTime? startAt;
  final DateTime? endAt;

  EmployeeDto({
    required this.profileId,
    required this.userName,
    this.phone = '',
    this.email = '',
    this.avatarUrl,
    this.isAlreadyHired = false,
    this.isActive = true,
    this.status = '',
    this.statusLabel,
    this.startAt,
    this.endAt,
  });

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      final value = raw.toString().trim();
      if (value.isEmpty) return null;
      return DateFormatter.parseApiDateTime(value);
    }

    final rawStatus = json['status'] ?? json['Status'] ?? '';
    final statusCode = referenceCodeFromDynamic(rawStatus)
      .trim()
      .toLowerCase();
    final statusLabel = referenceLabelFromDynamic(rawStatus)?.trim();
    final isAlreadyHired = json['isAlreadyHired'] as bool? ?? false;
    final isActive = json['isActive'] as bool? ??
        json['IsActive'] as bool? ??
      (statusCode == 'accepted' || statusCode == 'active' || isAlreadyHired);

    return EmployeeDto(
      profileId: json['profileId'] as String? ??
          json['employeeId'] as String? ??
          json['userId'] as String? ??
          '',
      userName:
          json['userName'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isAlreadyHired: isAlreadyHired,
      isActive: isActive,
      status: statusCode,
      statusLabel: statusLabel,
      startAt: parseDate(json['startAt'] ?? json['StartAt']),
      endAt: parseDate(json['endAt'] ?? json['EndAt']),
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
      'isActive': isActive,
      'status': status,
      'statusLabel': statusLabel,
      'startAt': startAt != null ? DateFormatter.toApiUtcIsoString(startAt!) : null,
      'endAt': endAt != null ? DateFormatter.toApiUtcIsoString(endAt!) : null,
    };
  }
}
