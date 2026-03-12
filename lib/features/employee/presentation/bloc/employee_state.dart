import 'package:equatable/equatable.dart';
import '../../domain/entities/employee_entity.dart';

abstract class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object?> get props => [];
}

class EmployeeInitial extends EmployeeState {}

class EmployeeLoading extends EmployeeState {}

class EmployeeLoaded extends EmployeeState {
  final List<EmployeeEntity> allEmployees;
  final List<EmployeeEntity> filteredEmployees;
  final int activeCount;
  final int pendingCount;
  final int totalCount;
  final int currentTab; // 0: All, 1: Active, 2: Pending

  const EmployeeLoaded({
    required this.allEmployees,
    required this.filteredEmployees,
    required this.activeCount,
    required this.pendingCount,
    required this.totalCount,
    required this.currentTab,
  });

  EmployeeLoaded copyWith({
    List<EmployeeEntity>? allEmployees,
    List<EmployeeEntity>? filteredEmployees,
    int? activeCount,
    int? pendingCount,
    int? totalCount,
    int? currentTab,
  }) {
    return EmployeeLoaded(
      allEmployees: allEmployees ?? this.allEmployees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      activeCount: activeCount ?? this.activeCount,
      pendingCount: pendingCount ?? this.pendingCount,
      totalCount: totalCount ?? this.totalCount,
      currentTab: currentTab ?? this.currentTab,
    );
  }

  @override
  List<Object?> get props => [
        allEmployees,
        filteredEmployees,
        activeCount,
        pendingCount,
        totalCount,
        currentTab,
      ];
}

class EmployeeActionInProgress extends EmployeeState {}

class EmployeeActionSuccess extends EmployeeState {
  final String message;
  const EmployeeActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class EmployeeFailure extends EmployeeState {
  final String message;
  const EmployeeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
