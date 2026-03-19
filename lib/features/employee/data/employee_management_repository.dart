
import '../domain/entities/employee_entity.dart';
import 'employee_api_service.dart';
import '../../location/data/location_api_service.dart';

abstract class EmployeeManagementRepository {
  Future<List<EmployeeEntity>> getEmployees(String businessId);
  Future<List<EmployeeEntity>> searchEmployees(String query);
  Future<void> addEmployee(String businessId, String employeeId);
  Future<EmployeeEntity> updateEmployee(String employeeId, EmployeeEntity updateData);
  Future<void> deleteEmployee(String employeeId);
}

class EmployeeManagementRepositoryApi implements EmployeeManagementRepository {
  final EmployeeApiService _apiService;
  final LocationApiService _locationApiService;

  EmployeeManagementRepositoryApi({
    required EmployeeApiService apiService,
    required LocationApiService locationApiService,
  })  : _apiService = apiService,
        _locationApiService = locationApiService;

  @override
  Future<List<EmployeeEntity>> getEmployees(String businessId) async {
    final employees = await _apiService.getMyEmployees();
    return employees
        .map(
          (employee) => EmployeeEntity(
            id: employee.profileId,
            name: employee.userName,
            phone: employee.phone,
            email: employee.email,
            status: employee.isAlreadyHired
                ? EmployeeStatus.active
                : EmployeeStatus.pending,
            assignedBusinessId: businessId,
          ),
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
            status: employee.isAlreadyHired
                ? EmployeeStatus.active
                : EmployeeStatus.pending,
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
    final ownedLocations = await _locationApiService.getMyOwnedLocations();

    final currentAssigned = ownedLocations.data
        .where((location) => location.employeeIds.contains(employeeId))
        .map((location) => location.id.toString())
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

    return updateData;
  }

  @override
  Future<void> deleteEmployee(String employeeId) {
    return _apiService.deleteEmployee(employeeId);
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
      assignedBusinessId: 'biz_01',
      assignedLocationIds: [],
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
    _mockEmployees.removeWhere((e) => e.id == employeeId);
  }
}
