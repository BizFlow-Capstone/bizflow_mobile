import 'package:uuid/uuid.dart';
import '../domain/entities/employee_entity.dart';

abstract class EmployeeManagementRepository {
  Future<List<EmployeeEntity>> getEmployees(String businessId);
  Future<EmployeeEntity> addEmployee(String businessId, EmployeeEntity employee);
  Future<EmployeeEntity> updateEmployee(String employeeId, EmployeeEntity updateData);
  Future<void> deleteEmployee(String employeeId);
}

class EmployeeManagementRepositoryMock implements EmployeeManagementRepository {
  final _uuid = const Uuid();
  
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
  Future<EmployeeEntity> addEmployee(String businessId, EmployeeEntity employee) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newEmployee = employee.copyWith(
      id: _uuid.v4(),
      assignedBusinessId: businessId,
    );
    _mockEmployees.insert(0, newEmployee);
    return newEmployee;
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
