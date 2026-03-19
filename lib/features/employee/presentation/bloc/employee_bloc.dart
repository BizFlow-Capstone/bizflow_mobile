import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../domain/entities/employee_entity.dart';
import '../../data/employee_management_repository.dart';
import 'employee_event.dart';
import 'employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final EmployeeManagementRepository _repository;
  final CacheManager _cacheManager = CacheManager();

  EmployeeBloc({required EmployeeManagementRepository repository})
      : _repository = repository,
        super(EmployeeInitial()) {
    on<LoadEmployeesRequested>(_onLoadEmployees);
    on<SelectEmployeeTabRequested>(_onSelectTab);
      on<SearchEmployeeKeywordChanged>(_onSearchKeywordChanged);
      on<SearchEmployeesRequested>(_onSearchEmployees);
    on<AddEmployeeRequested>(_onAddEmployee);
    on<AddMultipleEmployeesRequested>(_onAddMultipleEmployees);
    on<UpdateEmployeeRequested>(_onUpdateEmployee);
    on<DeleteEmployeeRequested>(_onDeleteEmployee);
  }

  Future<void> _onLoadEmployees(
    LoadEmployeesRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final cacheKey = 'employees_${event.businessId}';

    if (state is! EmployeeLoaded) {
      emit(EmployeeLoading());
    }

    await _cacheManager.fetchWithSWR<List<EmployeeEntity>>(
      key: cacheKey,
      fetcher: () => _repository.getEmployees(event.businessId),
      onData: (data, isFromCache) {
        if (!isClosed) {
          emit(
            _createLoadedState(
              data,
              state is EmployeeLoaded ? (state as EmployeeLoaded).currentTab : 0,
              state is EmployeeLoaded
                  ? (state as EmployeeLoaded).searchKeyword
                  : '',
            ),
          );
        }
      },
      onError: (error) {
        if (!isClosed && state is! EmployeeLoaded) {
          emit(EmployeeFailure(error.toString()));
        }
      },
    );
  }

  void _onSelectTab(
    SelectEmployeeTabRequested event,
    Emitter<EmployeeState> emit,
  ) {
    if (state is EmployeeLoaded) {
      final currentState = state as EmployeeLoaded;
      emit(
        _createLoadedState(
          currentState.allEmployees,
          event.tabIndex,
          currentState.searchKeyword,
        ),
      );
    }
  }

  void _onSearchKeywordChanged(
    SearchEmployeeKeywordChanged event,
    Emitter<EmployeeState> emit,
  ) {
    if (state is EmployeeLoaded) {
      final currentState = state as EmployeeLoaded;
      emit(
        _createLoadedState(
          currentState.allEmployees,
          currentState.currentTab,
          event.keyword,
        ),
      );
    }
  }

  Future<void> _onSearchEmployees(
    SearchEmployeesRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final currentState = state;
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const EmployeeSearchLoaded([]));
      if (currentState is EmployeeLoaded) emit(currentState);
      return;
    }

    try {
      final results = await _repository.searchEmployees(query);
      emit(EmployeeSearchLoaded(results));
      if (currentState is EmployeeLoaded) emit(currentState);
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      if (currentState is EmployeeLoaded) emit(currentState);
    }
  }

  Future<void> _onAddEmployee(
    AddEmployeeRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeLoaded) return;

    emit(EmployeeActionInProgress());

    try {
      await _repository.addEmployee(event.businessId, event.employeeId);
      
      emit(const EmployeeActionSuccess('Gửi lời mời thành công'));
      emit(currentState); // Phục hồi state để list page không bị trắng màn

      // Request a reload from network since the employee is pending
      add(LoadEmployeesRequested(businessId: event.businessId));

    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onAddMultipleEmployees(
    AddMultipleEmployeesRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeLoaded) return;

    emit(EmployeeActionInProgress());

    try {
      // Gọi vòng lặp để invite nhiều user
      for (final id in event.employeeIds) {
        await _repository.addEmployee(event.businessId, id);
      }
      
      emit(const EmployeeActionSuccess('Gửi lời mời thành công'));
      emit(currentState); // Phục hồi state để list page không bị trắng màn

      // Request a reload from network
      add(LoadEmployeesRequested(businessId: event.businessId));
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onUpdateEmployee(
    UpdateEmployeeRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeLoaded) return;

    final allEmployees = List<EmployeeEntity>.from(currentState.allEmployees);

    emit(EmployeeActionInProgress());

    try {
      final updatedEmployee = await _repository.updateEmployee(event.employee.id, event.employee);
      
      final index = allEmployees.indexWhere((e) => e.id == updatedEmployee.id);
      if (index != -1) {
        allEmployees[index] = updatedEmployee;
        // _cacheManager.setCache(cacheKey, allEmployees);
      }

      emit(const EmployeeActionSuccess('Cập nhật nhân viên thành công'));
      emit(
        _createLoadedState(
          allEmployees,
          currentState.currentTab,
          currentState.searchKeyword,
        ),
      );
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onDeleteEmployee(
    DeleteEmployeeRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeLoaded) return;

    final allEmployees = List<EmployeeEntity>.from(currentState.allEmployees);
    
    // Find businessId of deleted employee for cache key
    final empIdx = allEmployees.indexWhere((e) => e.id == event.employeeId);
    if (empIdx == -1) return;

    emit(EmployeeActionInProgress());

    try {
      await _repository.deleteEmployee(event.employeeId);
      
      allEmployees.removeAt(empIdx);
      // _cacheManager.setCache(cacheKey, allEmployees);

      emit(const EmployeeActionSuccess('Xóa nhân viên thành công'));
      emit(
        _createLoadedState(
          allEmployees,
          currentState.currentTab,
          currentState.searchKeyword,
        ),
      );
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      emit(currentState);
    }
  }

  EmployeeLoaded _createLoadedState(
    List<EmployeeEntity> employees,
    int tabIndex,
    String searchKeyword,
  ) {
    List<EmployeeEntity> filtered = [];
    
    if (tabIndex == 0) {
      filtered = employees; // All
    } else if (tabIndex == 1) {
      filtered = employees.where((e) => e.status == EmployeeStatus.active).toList(); // Active
    } else if (tabIndex == 2) {
      filtered = employees.where((e) => e.status == EmployeeStatus.pending).toList(); // Pending
    }

    final keyword = searchKeyword.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((employee) {
        return employee.name.toLowerCase().contains(keyword) ||
            employee.phone.toLowerCase().contains(keyword) ||
            employee.email.toLowerCase().contains(keyword);
      }).toList();
    }

    final activeCount = employees.where((e) => e.status == EmployeeStatus.active).length;
    final pendingCount = employees.where((e) => e.status == EmployeeStatus.pending).length;
    final totalCount = employees.length;

    return EmployeeLoaded(
      allEmployees: employees,
      filteredEmployees: filtered,
      activeCount: activeCount,
      pendingCount: pendingCount,
      totalCount: totalCount,
      currentTab: tabIndex,
      searchKeyword: searchKeyword,
    );
  }
}
