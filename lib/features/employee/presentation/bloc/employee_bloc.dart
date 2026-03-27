import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/utils/date_formatter.dart';
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
      fromJson: (json) {
        final dataList = json['data'] as List? ?? [];
        return dataList.map((item) {
          return EmployeeEntity(
            id: item['id'] ?? '',
            name: item['name'] ?? '',
            phone: item['phone'] ?? '',
            email: item['email'] ?? '',
            status: EmployeeStatus.values.firstWhere(
              (e) => e.name == (item['status'] ?? 'active'),
              orElse: () => EmployeeStatus.active,
            ),
            isActive: item['isActive'] ?? true,
            employmentStatus: item['employmentStatus'] ?? '',
            startedAt: item['startedAt'] != null ? DateTime.parse(item['startedAt']) : null,
            endedAt: item['endedAt'] != null ? DateTime.parse(item['endedAt']) : null,
            assignedBusinessId: item['assignedBusinessId'] ?? '',
            assignedLocationIds: List<String>.from(item['assignedLocationIds'] ?? []),
            assignedLocationNames: List<String>.from(item['assignedLocationNames'] ?? []),
          );
        }).toList();
      },
      toJson: (data) {
        return {
          'data': data
              .map(
                (e) => {
                  'id': e.id,
                  'name': e.name,
                  'phone': e.phone,
                  'email': e.email,
                  'status': e.status.name,
                  'isActive': e.isActive,
                  'employmentStatus': e.employmentStatus,
                  'startedAt': e.startedAt != null
                    ? DateFormatter.toApiUtcIsoString(e.startedAt!)
                    : null,
                  'endedAt': e.endedAt != null
                    ? DateFormatter.toApiUtcIsoString(e.endedAt!)
                    : null,
                  'assignedBusinessId': e.assignedBusinessId,
                  'assignedLocationIds': e.assignedLocationIds,
                  'assignedLocationNames': e.assignedLocationNames,
                },
              )
              .toList(),
        };
      },
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

    emit(EmployeeActionInProgress());

    try {
      await _repository.updateEmployee(event.employee.id, event.employee);

      emit(const EmployeeActionSuccess('Cập nhật nhân viên thành công'));
      await _reloadEmployeesFromServer(currentState, emit);
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
    final empIdx = allEmployees.indexWhere((e) => e.id == event.employeeId);
    if (empIdx == -1) return;

    emit(EmployeeActionInProgress());

    try {
      await _repository.deleteEmployee(event.employeeId);

      emit(const EmployeeActionSuccess('Cập nhật trạng thái nhân viên thành công'));
      await _reloadEmployeesFromServer(currentState, emit);
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _reloadEmployeesFromServer(
    EmployeeLoaded currentState,
    Emitter<EmployeeState> emit,
  ) async {
    final businessId = currentState.allEmployees.firstWhere(
      (e) => e.assignedBusinessId.trim().isNotEmpty,
      orElse: () => const EmployeeEntity(id: '', name: ''),
    ).assignedBusinessId;

    if (businessId.isEmpty) {
      emit(
        _createLoadedState(
          currentState.allEmployees,
          currentState.currentTab,
          currentState.searchKeyword,
        ),
      );
      return;
    }

    final freshEmployees = await _repository.getEmployees(businessId);
    await _cacheManager.set(
      'employees_$businessId',
      {
        'data': freshEmployees
            .map(
              (e) => {
                'id': e.id,
                'name': e.name,
                'phone': e.phone,
                'email': e.email,
                'status': e.status.name,
                'isActive': e.isActive,
                'employmentStatus': e.employmentStatus,
                'startedAt': e.startedAt != null
                  ? DateFormatter.toApiUtcIsoString(e.startedAt!)
                  : null,
                'endedAt': e.endedAt != null
                  ? DateFormatter.toApiUtcIsoString(e.endedAt!)
                  : null,
                'assignedBusinessId': e.assignedBusinessId,
                'assignedLocationIds': e.assignedLocationIds,
                'assignedLocationNames': e.assignedLocationNames,
              },
            )
            .toList(),
      },
    );

    emit(
      _createLoadedState(
        freshEmployees,
        currentState.currentTab,
        currentState.searchKeyword,
      ),
    );
  }

  EmployeeLoaded _createLoadedState(
    List<EmployeeEntity> employees,
    int tabIndex,
    String searchKeyword,
  ) {
    List<EmployeeEntity> filtered = [];

    final safeTabIndex = tabIndex.clamp(0, 3);

    if (safeTabIndex == 0) {
      filtered = employees.where((e) => e.isActive).toList(); // All (active only)
    } else if (safeTabIndex == 1) {
      filtered = employees
          .where((e) => e.isActive && e.status == EmployeeStatus.active)
          .toList(); // Active
    } else if (safeTabIndex == 2) {
      filtered = employees.where((e) => e.status == EmployeeStatus.pending).toList(); // Pending
    } else if (safeTabIndex == 3) {
      filtered = employees.where((e) => !e.isActive).toList(); // History
    }

    final keyword = searchKeyword.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((employee) {
        return employee.name.toLowerCase().contains(keyword) ||
            employee.phone.toLowerCase().contains(keyword) ||
            employee.email.toLowerCase().contains(keyword);
      }).toList();
    }

    if (safeTabIndex == 3) {
      filtered.sort((a, b) {
        final aTime = a.endedAt ?? a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final bTime = b.endedAt ?? b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final cmp = bTime.compareTo(aTime);
        if (cmp != 0) return cmp;
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      });
    }

    final activeCount = employees
        .where((e) => e.isActive && e.status == EmployeeStatus.active)
        .length;
    final pendingCount = employees.where((e) => e.status == EmployeeStatus.pending).length;
    final historyCount = employees.where((e) => !e.isActive).length;
    final totalCount = employees.length;

    return EmployeeLoaded(
      allEmployees: employees,
      filteredEmployees: filtered,
      activeCount: activeCount,
      pendingCount: pendingCount,
      historyCount: historyCount,
      totalCount: totalCount,
      currentTab: safeTabIndex,
      searchKeyword: searchKeyword,
    );
  }
}
