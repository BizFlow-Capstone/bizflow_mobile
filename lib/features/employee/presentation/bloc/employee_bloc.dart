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
    on<AddEmployeeRequested>(_onAddEmployee);
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
          emit(_createLoadedState(data, state is EmployeeLoaded ? (state as EmployeeLoaded).currentTab : 0));
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
      emit(_createLoadedState(currentState.allEmployees, event.tabIndex));
    }
  }

  Future<void> _onAddEmployee(
    AddEmployeeRequested event,
    Emitter<EmployeeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeLoaded) return;

    final allEmployees = List<EmployeeEntity>.from(currentState.allEmployees);

    emit(EmployeeActionInProgress());

    try {
      final newEmployee = await _repository.addEmployee(event.businessId, event.employee);
      
      // Update local copy and cache
      allEmployees.insert(0, newEmployee);
      
      // CacheManager set expects a map, but we can serialize to a basic map if needed.
      // Since it's mockup, we can use the simplest approach. CacheManager uses local_storage which requires JSON encodable.
      // But actually the Entity needs toMap(). Let's define it later if needed, but for mock repo memory list might just be fine, or we can just ignore caching new objects locally without toMap. 
      // Actually we'll skip caching for the mock write since it's just mock data memory.
      // Wait, CacheManager.set(key, data) needs `Map<String, dynamic> data`.
      // Let's just comment it out since it's mock and memory lists are sufficient for this demo.
      // _cacheManager.setCache(cacheKey, allEmployees);

      emit(const EmployeeActionSuccess('Thêm nhân viên thành công'));
      emit(_createLoadedState(allEmployees, currentState.currentTab));
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
      emit(_createLoadedState(allEmployees, currentState.currentTab));
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
      emit(_createLoadedState(allEmployees, currentState.currentTab));
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      emit(currentState);
    }
  }

  EmployeeLoaded _createLoadedState(List<EmployeeEntity> employees, int tabIndex) {
    List<EmployeeEntity> filtered = [];
    
    if (tabIndex == 0) {
      filtered = employees; // All
    } else if (tabIndex == 1) {
      filtered = employees.where((e) => e.status == EmployeeStatus.active).toList(); // Active
    } else if (tabIndex == 2) {
      filtered = employees.where((e) => e.status == EmployeeStatus.pending).toList(); // Pending
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
    );
  }
}
