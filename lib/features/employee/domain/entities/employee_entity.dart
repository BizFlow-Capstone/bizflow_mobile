import 'package:equatable/equatable.dart';

enum EmployeeStatus { active, pending, inactive, rejected }

/// Employee Entity - Domain model
class EmployeeEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final EmployeeStatus status;
  final String? statusLabel;
  final bool isActive;
  final String employmentStatus;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String assignedBusinessId;
  final List<String> assignedLocationIds;
  final List<String> assignedLocationNames;

  const EmployeeEntity({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.status = EmployeeStatus.active,
    this.statusLabel,
    this.isActive = true,
    this.employmentStatus = 'accepted',
    this.startedAt,
    this.endedAt,
    this.assignedBusinessId = '',
    this.assignedLocationIds = const [],
    this.assignedLocationNames = const [],
  });

  EmployeeEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    EmployeeStatus? status,
    String? statusLabel,
    bool? isActive,
    String? employmentStatus,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? endedAt,
    bool clearEndedAt = false,
    String? assignedBusinessId,
    List<String>? assignedLocationIds,
    List<String>? assignedLocationNames,
  }) {
    return EmployeeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      isActive: isActive ?? this.isActive,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      assignedBusinessId: assignedBusinessId ?? this.assignedBusinessId,
      assignedLocationIds: assignedLocationIds ?? this.assignedLocationIds,
      assignedLocationNames: assignedLocationNames ?? this.assignedLocationNames,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        status,
        statusLabel,
        isActive,
        employmentStatus,
        startedAt,
        endedAt,
        assignedBusinessId,
        assignedLocationIds,
        assignedLocationNames,
      ];
}
