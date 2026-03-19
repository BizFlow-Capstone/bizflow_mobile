import 'package:flutter/foundation.dart';
import '../domain/entities/employee_entity.dart';
import 'employee_api_service.dart';
import 'models/employee_invitation_dto.dart';

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
              id: dto.profileId,
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

  Future<List<EmployeeInvitationDto>> getPendingInvitations() async {
    try {
      return await _service.getPendingInvitations();
    } catch (e) {
      debugPrint('EmployeeRepository.getPendingInvitations error: $e');
      rethrow;
    }
  }

  Future<void> acceptInvitation(int hireId) async {
    try {
      await _service.acceptInvitation(hireId);
    } catch (e) {
      debugPrint('EmployeeRepository.acceptInvitation error: $e');
      rethrow;
    }
  }

  Future<void> rejectInvitation(int hireId) async {
    try {
      await _service.rejectInvitation(hireId);
    } catch (e) {
      debugPrint('EmployeeRepository.rejectInvitation error: $e');
      rethrow;
    }
  }
}
