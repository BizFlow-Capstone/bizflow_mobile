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
  final int historyCount;
  final int totalCount;
  final int currentTab; // 0: All, 1: Active, 2: Pending, 3: History
  final String searchKeyword;

  const EmployeeLoaded({
    required this.allEmployees,
    required this.filteredEmployees,
    required this.activeCount,
    required this.pendingCount,
    required this.historyCount,
    required this.totalCount,
    required this.currentTab,
    required this.searchKeyword,
  });

  EmployeeLoaded copyWith({
    List<EmployeeEntity>? allEmployees,
    List<EmployeeEntity>? filteredEmployees,
    int? activeCount,
    int? pendingCount,
    int? historyCount,
    int? totalCount,
    int? currentTab,
    String? searchKeyword,
  }) {
    return EmployeeLoaded(
      allEmployees: allEmployees ?? this.allEmployees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      activeCount: activeCount ?? this.activeCount,
      pendingCount: pendingCount ?? this.pendingCount,
      historyCount: historyCount ?? this.historyCount,
      totalCount: totalCount ?? this.totalCount,
      currentTab: currentTab ?? this.currentTab,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }

  @override
  List<Object?> get props => [
        allEmployees,
        filteredEmployees,
        activeCount,
        pendingCount,
        historyCount,
        totalCount,
        currentTab,
        searchKeyword,
      ];
}

class EmployeeSearchLoaded extends EmployeeState {
  final List<EmployeeEntity> results;

  const EmployeeSearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
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
