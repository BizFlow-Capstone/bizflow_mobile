import "../../../../shared/cache/cache_manager.dart";
import 'package:flutter/foundation.dart';
import '../domain/entities/employee_entity.dart';
import 'employee_api_service.dart';
import 'models/employee_invitation_dto.dart';
import '../../../core/storage/local_storage.dart';

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
      final dtos = await _service.getAssignableEmployees();
      EmployeeStatus toEmployeeStatus(String rawStatus, bool isActive) {
        final status = rawStatus.toLowerCase();
        switch (status) {
          case 'active':
          case 'accepted':
            return isActive ? EmployeeStatus.active : EmployeeStatus.inactive;
          case 'pending':
            return EmployeeStatus.pending;
          case 'inactive':
          case 'terminated':
          case 'deleted':
            return EmployeeStatus.inactive;
          case 'rejected':
            return EmployeeStatus.rejected;
          default:
            return isActive ? EmployeeStatus.active : EmployeeStatus.inactive;
        }
      }

      return dtos
          .map(
            (dto) => EmployeeEntity(
              id: dto.profileId,
              name: dto.userName,
              phone: dto.phone,
              email: dto.email,
              status: toEmployeeStatus(dto.status, dto.isActive),
              isActive: dto.isActive,
              employmentStatus: dto.status,
              startedAt: dto.startAt,
              endedAt: dto.endAt,
            ),
          )
          .where(
            (employee) =>
                employee.isActive &&
                employee.status == EmployeeStatus.active &&
                employee.endedAt == null,
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

  Future<void> acceptInvitation(EmployeeInvitationDto invitation) async {
    try {await _service.acceptInvitation(invitation.hireId);
      final store = await LocalStorage.getInstance();
      final userName = store.getString(StorageKeys.currentUserFullName) ?? "Một nhân viên";
      await _service.sendInvitationReply(invitation.ownerId, true, userName);
      await clearCache();
    } catch (e) {
      debugPrint('EmployeeRepository.acceptInvitation error: $e');
      rethrow;
    }
  }

  Future<void> rejectInvitation(EmployeeInvitationDto invitation) async {
    try {await _service.rejectInvitation(invitation.hireId);
      final store = await LocalStorage.getInstance();
      final userName = store.getString(StorageKeys.currentUserFullName) ?? "Một nhân viên";
      await _service.sendInvitationReply(invitation.ownerId, false, userName);
      await clearCache();
    } catch (e) {
      debugPrint('EmployeeRepository.rejectInvitation error: $e');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    await CacheManager().removeByPrefix("cache_employees_");
    await CacheManager().removeByPrefix("employees_");
  }
}
