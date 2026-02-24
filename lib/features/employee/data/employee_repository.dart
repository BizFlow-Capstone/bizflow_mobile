import 'package:flutter/foundation.dart';
import '../domain/entities/employee_entity.dart';
import 'employee_api_service.dart';

/// Employee Repository - Orchestrates employee data flow
///
/// Architecture: BLoC → Repository → Service → ApiClient
class EmployeeRepository {
  final EmployeeApiService _service;

  EmployeeRepository({required EmployeeApiService service})
    : _service = service;

  /// Get list of employees available for assignment
  Future<List<EmployeeEntity>> getAvailableEmployees() async {
    try {
      final dtos = await _service.getMyEmployees();
      return dtos
          .map(
            (dto) => EmployeeEntity(
              id: dto.userId,
              name: dto.userName,
              phone: dto.phone,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('EmployeeRepository.getAvailableEmployees error: $e');
      rethrow;
    }
  }
}
