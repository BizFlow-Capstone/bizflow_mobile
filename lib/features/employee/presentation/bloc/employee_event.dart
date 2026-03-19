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

class SearchEmployeeKeywordChanged extends EmployeeEvent {
  final String keyword;

  const SearchEmployeeKeywordChanged(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

class SearchEmployeesRequested extends EmployeeEvent {
  final String query;

  const SearchEmployeesRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class AddEmployeeRequested extends EmployeeEvent {
  final String businessId;
  final String employeeId;

  const AddEmployeeRequested({required this.businessId, required this.employeeId});

  @override
  List<Object?> get props => [businessId, employeeId];
}

class AddMultipleEmployeesRequested extends EmployeeEvent {
  final String businessId;
  final List<String> employeeIds;

  const AddMultipleEmployeesRequested({required this.businessId, required this.employeeIds});

  @override
  List<Object?> get props => [businessId, employeeIds];
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
