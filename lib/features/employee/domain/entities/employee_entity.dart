import 'package:equatable/equatable.dart';

enum EmployeeStatus { active, pending }

/// Employee Entity - Domain model
class EmployeeEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final EmployeeStatus status;
  final String assignedBusinessId;
  final List<String> assignedLocationIds;

  const EmployeeEntity({
    required this.id, 
    required this.name, 
    this.phone = '',
    this.email = '',
    this.status = EmployeeStatus.active,
    this.assignedBusinessId = '',
    this.assignedLocationIds = const [],
  });

  EmployeeEntity copyWith({
    String? id, 
    String? name, 
    String? phone,
    String? email,
    EmployeeStatus? status,
    String? assignedBusinessId,
    List<String>? assignedLocationIds,
  }) {
    return EmployeeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      assignedBusinessId: assignedBusinessId ?? this.assignedBusinessId,
      assignedLocationIds: assignedLocationIds ?? this.assignedLocationIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        status,
        assignedBusinessId,
        assignedLocationIds,
      ];
}
