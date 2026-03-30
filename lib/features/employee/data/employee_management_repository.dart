
import '../domain/entities/employee_entity.dart';
import 'employee_api_service.dart';
import 'models/employee_dto.dart';
import '../../location/data/location_api_service.dart';
import '../../../shared/cache/cache_manager.dart';

abstract class EmployeeManagementRepository {
  Future<List<EmployeeEntity>> getEmployees(String businessId);
  Future<List<EmployeeEntity>> searchEmployees(String query);
  Future<void> addEmployee(String businessId, String employeeId);
  Future<EmployeeEntity> updateEmployee(String employeeId, EmployeeEntity updateData);
  Future<void> deleteEmployee(String employeeId);
}

class EmployeeManagementRepositoryApi implements EmployeeManagementRepository {
  static const String _assignmentCacheKey = 'employee_location_assignments';

  final EmployeeApiService _apiService;
  final LocationApiService _locationApiService;
  _EmployeeAssignmentMap? _assignmentMemoryCache;

  EmployeeManagementRepositoryApi({
    required EmployeeApiService apiService,
    required LocationApiService locationApiService,
  })  : _apiService = apiService,
        _locationApiService = locationApiService;

  @override
  Future<List<EmployeeEntity>> getEmployees(String businessId) async {
    final employees = await _apiService.getMyEmployees();
    final assignmentMap = await _getEmployeeLocationAssignments();

    return employees
        .map(
          (employee) {
            final employeeId = employee.profileId;
            return EmployeeEntity(
            id: employee.profileId,
            name: employee.userName,
            phone: employee.phone,
            email: employee.email,
            status: _toEmployeeStatus(employee),
            isActive: employee.isActive,
            employmentStatus: employee.status,
            startedAt: employee.startAt,
            endedAt: employee.endAt,
            assignedBusinessId: businessId,
            assignedLocationIds:
                assignmentMap.locationIdsByEmployee[employeeId] ?? const [],
            assignedLocationNames:
                assignmentMap.locationNamesByEmployee[employeeId] ?? const [],
          );
          },
        )
        .toList();
  }

  @override
  Future<List<EmployeeEntity>> searchEmployees(String query) async {
    final employees = await _apiService.searchEmployees(query);
    return employees
        .map(
          (employee) => EmployeeEntity(
            id: employee.profileId,
            name: employee.userName,
            phone: employee.phone,
            email: employee.email,
            status: _toEmployeeStatus(employee),
            isActive: employee.isActive,
            employmentStatus: employee.status,
            startedAt: employee.startAt,
            endedAt: employee.endAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> addEmployee(
    String businessId,
    String employeeId,
  ) async {
    await _apiService.inviteEmployee(employeeId);
  }

  @override
  Future<EmployeeEntity> updateEmployee(
    String employeeId,
    EmployeeEntity updateData,
  ) async {
    final assignmentMap = await _getEmployeeLocationAssignments();

    final currentAssigned =
        (assignmentMap.locationIdsByEmployee[employeeId] ?? const <String>[])
            .toSet();

    final targetAssigned = updateData.assignedLocationIds.toSet();

    final toAssign = targetAssigned.difference(currentAssigned);
    final toUnassign = currentAssigned.difference(targetAssigned);

    for (final locationId in toAssign) {
      await _locationApiService.addEmployeesToLocation(
        locationId: locationId,
        employeeIds: [employeeId],
      );
    }

    for (final locationId in toUnassign) {
      await _locationApiService.removeEmployeeFromLocation(
        locationId: locationId,
        employeeId: employeeId,
      );
    }

    final refreshedAssignmentMap = await _getEmployeeLocationAssignments(
      forceRefresh: true,
    );
    return updateData.copyWith(
      assignedLocationIds:
          refreshedAssignmentMap.locationIdsByEmployee[employeeId] ?? const [],
      assignedLocationNames:
          refreshedAssignmentMap.locationNamesByEmployee[employeeId] ?? const [],
    );
  }

  @override
  Future<void> deleteEmployee(String employeeId) {
    return _apiService.deleteEmployee(employeeId);
  }

  EmployeeStatus _toEmployeeStatus(EmployeeDto employee) {
    switch (employee.status.toLowerCase()) {
      case 'pending':
        return EmployeeStatus.pending;
      case 'rejected':
        return EmployeeStatus.rejected;
      case 'inactive':
      case 'terminated':
      case 'deleted':
        return EmployeeStatus.inactive;
      case 'accepted':
      case 'active':
        return employee.isActive ? EmployeeStatus.active : EmployeeStatus.inactive;
      default:
        // if status is empty but isAlreadyHired is true, check isActive
        if (employee.status.isEmpty && employee.isAlreadyHired) {
          return employee.isActive ? EmployeeStatus.active : EmployeeStatus.inactive;
        }
        return EmployeeStatus.pending;
    }
  }

  Future<_EmployeeAssignmentMap> _getEmployeeLocationAssignments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _assignmentMemoryCache != null) {
      return _assignmentMemoryCache!;
    }

    if (!forceRefresh) {
      final cached = await CacheManager().get(_assignmentCacheKey);
      if (cached != null) {
        final cachedMap = _EmployeeAssignmentMap.fromCache(cached);
        _assignmentMemoryCache = cachedMap;
        return cachedMap;
      }
    }

    final freshMap = await _loadEmployeeLocationAssignmentsFromApi();
    _assignmentMemoryCache = freshMap;
    await CacheManager().set(_assignmentCacheKey, freshMap.toCache());
    return freshMap;
  }

  Future<_EmployeeAssignmentMap> _loadEmployeeLocationAssignmentsFromApi() async {
    final ownedLocations = await _locationApiService.getMyOwnedLocations();
    final locationIdsByEmployee = <String, Set<String>>{};
    final locationNamesByEmployee = <String, Set<String>>{};

    for (final location in ownedLocations.data) {
      final locationId = location.id.toString();
      final locationEmployees = await _locationApiService.getLocationEmployees(
        locationId: locationId,
      );

      for (final employee in locationEmployees) {
        final employeeId = employee.profileId;
        if (employeeId.isEmpty) continue;

        locationIdsByEmployee
            .putIfAbsent(employeeId, () => <String>{})
            .add(locationId);
        locationNamesByEmployee
            .putIfAbsent(employeeId, () => <String>{})
            .add(location.name);
      }
    }

    return _EmployeeAssignmentMap(
      locationIdsByEmployee: locationIdsByEmployee.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      locationNamesByEmployee: locationNamesByEmployee.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
    );
  }
}

class _EmployeeAssignmentMap {
  final Map<String, List<String>> locationIdsByEmployee;
  final Map<String, List<String>> locationNamesByEmployee;

  const _EmployeeAssignmentMap({
    required this.locationIdsByEmployee,
    required this.locationNamesByEmployee,
  });

  Map<String, dynamic> toCache() {
    return {
      'locationIdsByEmployee': locationIdsByEmployee,
      'locationNamesByEmployee': locationNamesByEmployee,
    };
  }

  static _EmployeeAssignmentMap fromCache(Map<String, dynamic> cache) {
    Map<String, List<String>> parseMap(dynamic raw) {
      if (raw is! Map) return <String, List<String>>{};
      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          (value is List)
              ? value.map((item) => item.toString()).toList()
              : <String>[],
        ),
      );
    }

    return _EmployeeAssignmentMap(
      locationIdsByEmployee: parseMap(cache['locationIdsByEmployee']),
      locationNamesByEmployee: parseMap(cache['locationNamesByEmployee']),
    );
  }
}

class EmployeeManagementRepositoryMock implements EmployeeManagementRepository {
  
  final List<EmployeeEntity> _mockEmployees = [
    const EmployeeEntity(
      id: 'emp_01',
      name: 'Nguyễn Thị Lan',
      email: 'lan.nt@bizflow.vn',
      phone: '0912 345 678',
      status: EmployeeStatus.active,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: ['loc_01', 'loc_02'],
    ),
    const EmployeeEntity(
      id: 'emp_02',
      name: 'Trần Văn Bảo',
      email: 'bao.tv@bizflow.vn',
      phone: '0987 654 321',
      status: EmployeeStatus.active,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: ['loc_01'],
    ),
    const EmployeeEntity(
      id: 'emp_03',
      name: 'Phạm Thu Hà',
      email: 'ha.pt@bizflow.vn',
      phone: '0909 090 090',
      status: EmployeeStatus.pending,
      isActive: false,
      employmentStatus: 'pending',
      startedAt: null,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: [],
    ),
    const EmployeeEntity(
      id: 'emp_04',
      name: 'Lê Minh Tuấn',
      email: 'tuan.lm@bizflow.vn',
      phone: '0945 678 901',
      status: EmployeeStatus.active,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: ['loc_02'],
    ),
    const EmployeeEntity(
      id: 'emp_05',
      name: 'Hoàng Thu Hương',
      email: 'huong.ht@bizflow.vn',
      phone: '0911 111 222',
      status: EmployeeStatus.active,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: ['loc_01', 'loc_02'],
    ),
    const EmployeeEntity(
      id: 'emp_06',
      name: 'Đỗ Văn Cường',
      email: 'cuong.dv@bizflow.vn',
      phone: '0933 444 555',
      status: EmployeeStatus.active,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: ['loc_03'],
    ),
    const EmployeeEntity(
      id: 'emp_07',
      name: 'Vũ Thị Mai',
      email: 'mai.vt@bizflow.vn',
      phone: '0977 888 999',
      status: EmployeeStatus.pending,
      isActive: false,
      employmentStatus: 'pending',
      startedAt: null,
      assignedBusinessId: 'biz_01',
      assignedLocationIds: [],
    ),
    EmployeeEntity(
      id: 'emp_08',
      name: 'Ngô Khánh Ly',
      email: 'ly.nk@bizflow.vn',
      phone: '0922 888 666',
      status: EmployeeStatus.inactive,
      isActive: false,
      employmentStatus: 'inactive',
      startedAt: DateTime.now().subtract(const Duration(days: 420)),
      endedAt: DateTime.now().subtract(const Duration(days: 12)),
      assignedBusinessId: 'biz_01',
      assignedLocationIds: const ['loc_01'],
      assignedLocationNames: const ['Kho HCM'],
    ),
  ];

  @override
  Future<List<EmployeeEntity>> getEmployees(String businessId) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    if (businessId.isEmpty) {
      return List.unmodifiable(_mockEmployees); // For safety, return all if no context
    }
    return _mockEmployees.where((e) => e.assignedBusinessId == businessId || e.assignedBusinessId == 'biz_01').toList(); // Fake filtering
  }

  @override
  Future<List<EmployeeEntity>> searchEmployees(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return [];

    return _mockEmployees.where((employee) {
      return employee.name.toLowerCase().contains(keyword) ||
          employee.phone.toLowerCase().contains(keyword) ||
          employee.email.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  Future<void> addEmployee(String businessId, String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<EmployeeEntity> updateEmployee(String employeeId, EmployeeEntity updateData) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _mockEmployees.indexWhere((e) => e.id == employeeId);
    if (index == -1) throw Exception('Employee not found');
    
    _mockEmployees[index] = updateData;
    return updateData;
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockEmployees.indexWhere((e) => e.id == employeeId);
    if (index == -1) return;

    final current = _mockEmployees[index];
    _mockEmployees[index] = current.copyWith(
      isActive: false,
      status: EmployeeStatus.inactive,
      employmentStatus: 'inactive',
      endedAt: DateTime.now(),
    );
  }
}
