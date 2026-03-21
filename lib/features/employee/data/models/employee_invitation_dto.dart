import '../../../../shared/utils/date_formatter.dart';

class EmployeeInvitationDto {
  final int hireId;
  final String ownerId;
  final String ownerName;
  final DateTime invitedAt;

  EmployeeInvitationDto({
    required this.hireId,
    required this.ownerId,
    required this.ownerName,
    required this.invitedAt,
  });

  factory EmployeeInvitationDto.fromJson(Map<String, dynamic> json) {
    return EmployeeInvitationDto(
      hireId: json['hireId'] as int? ?? 0,
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      invitedAt: DateFormatter.parseApiDateTime(
            json['invitedAt'] as String?,
            fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
    );
  }
}
