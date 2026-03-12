import 'package:equatable/equatable.dart';
import '../../domain/entities/employee_entity.dart';

abstract class EmployeeEvent extends Equatable {
  const EmployeeEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployeesRequested extends EmployeeEvent {
  final String businessId;

  const LoadEmployeesRequested({required this.businessId});

  @override
  List<Object?> get props => [businessId];
}

class SelectEmployeeTabRequested extends EmployeeEvent {
  final int tabIndex; // 0: All, 1: Active, 2: Pending

  const SelectEmployeeTabRequested(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class AddEmployeeRequested extends EmployeeEvent {
  final String businessId;
  final EmployeeEntity employee;

  const AddEmployeeRequested({required this.businessId, required this.employee});

  @override
  List<Object?> get props => [businessId, employee];
}

class UpdateEmployeeRequested extends EmployeeEvent {
  final EmployeeEntity employee;

  const UpdateEmployeeRequested(this.employee);

  @override
  List<Object?> get props => [employee];
}

class DeleteEmployeeRequested extends EmployeeEvent {
  final String employeeId;

  const DeleteEmployeeRequested(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}
