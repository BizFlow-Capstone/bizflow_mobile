import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/employee_dto.dart';
import 'models/employee_invitation_dto.dart';

/// Employee API Service - Handles employee-related API calls
///
/// Architecture: BLoC → Repository → Service → ApiClient → Backend
class EmployeeApiService {
  final ApiClient _apiClient;

  EmployeeApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  List<EmployeeDto> _dedupeEmployees(List<EmployeeDto> employees) {
    int statusRank(String status) {
      switch (status.toLowerCase()) {
        case 'active':
        case 'accepted':
          return 4;
        case 'pending':
          return 3;
        case 'inactive':
        case 'terminated':
        case 'deleted':
          return 2;
        case 'rejected':
          return 1;
        default:
          return 0;
      }
    }

    DateTime latestTouch(EmployeeDto dto) {
      return dto.endAt ?? dto.startAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    bool isBetter(EmployeeDto candidate, EmployeeDto current) {
      final candidateTouch = latestTouch(candidate);
      final currentTouch = latestTouch(current);
      final dateCompare = candidateTouch.compareTo(currentTouch);
      if (dateCompare != 0) return dateCompare > 0;

      if (candidate.isActive != current.isActive) {
        return candidate.isActive;
      }

      final candidateRank = statusRank(candidate.status);
      final currentRank = statusRank(current.status);
      if (candidateRank != currentRank) {
        return candidateRank > currentRank;
      }

      return false;
    }

    final byId = <String, EmployeeDto>{};
    for (final employee in employees) {
      final id = employee.profileId.trim();
      if (id.isEmpty) continue;

      final existing = byId[id];
      if (existing == null || isBetter(employee, existing)) {
        byId[id] = employee;
      }
    }

    return byId.values.toList();
  }

  /// Get employees available for assignment
  ///
  /// API: GET /api/my-employee/employees
  /// Returns: `List<EmployeeDto>`
  Future<List<EmployeeDto>> getMyEmployees() async {
    Future<List<EmployeeDto>> loadByEndpoint(String endpoint) async {
      final response = await _apiClient.get(endpoint);

      if (response.isSuccess && response.data != null) {
        final dto = EmployeeResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        return dto.employees;
      }

      throw Exception(response.message ?? 'Failed to load employees');
    }

    try {
      try {
        final employees = await loadByEndpoint(ApiEndpoints.myEmployeesDetails);
        return _dedupeEmployees(employees);
      } catch (_) {
        final employees = await loadByEndpoint(ApiEndpoints.myEmployees);
        return _dedupeEmployees(employees);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Session expired');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.getMyEmployees error: $e');
      rethrow;
    }
  }

  /// Get employees for location assignment flow.
  ///
  /// Prefer `/api/my-employee/employees` because it is the current/assignable list.
  /// Fallback to `.../employees/details` only when needed.
  Future<List<EmployeeDto>> getAssignableEmployees() async {
    Future<List<EmployeeDto>> loadByEndpoint(String endpoint) async {
      final response = await _apiClient.get(endpoint);

      if (response.isSuccess && response.data != null) {
        final dto = EmployeeResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        return dto.employees;
      }

      throw Exception(response.message ?? 'Failed to load employees');
    }

    try {
      try {
        final employees = await loadByEndpoint(ApiEndpoints.myEmployees);
        return _dedupeEmployees(employees);
      } catch (_) {
        final employees = await loadByEndpoint(ApiEndpoints.myEmployeesDetails);
        final deduped = _dedupeEmployees(employees);
        return deduped
            .where(
              (e) => e.status.toLowerCase() != 'rejected',
            )
            .toList();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Session expired');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.getAssignableEmployees error: $e');
      rethrow;
    }
  }

  Future<List<EmployeeDto>> searchEmployees(String query) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.searchEmployees,
        queryParams: {'query': query},
      );

      if (response.isSuccess && response.data != null) {
        final payload = response.data as Map<String, dynamic>;
        final rawData = payload['data'];
        final list = rawData is List<dynamic>
            ? rawData
            : <dynamic>[];
        final employees = list
            .map((item) => EmployeeDto.fromJson(item as Map<String, dynamic>))
            .toList();
        return _dedupeEmployees(employees);
      }

      throw Exception(response.message ?? 'Failed to search employees');
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.searchEmployees error: $e');
      rethrow;
    }
  }

  Future<void> inviteEmployee(String employeeId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.inviteEmployee,
        body: {'employeeId': employeeId},
      );

      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to invite employee');
      }
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.inviteEmployee error: $e');
      rethrow;
    }
  }

  Future<List<EmployeeInvitationDto>> getPendingInvitations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.employeeInvitations);

      if (response.isSuccess && response.data != null) {
        final payload = response.data as Map<String, dynamic>;
        final rawData = payload['data'];
        final list = rawData is List<dynamic> ? rawData : <dynamic>[];
        return list
            .map(
              (item) => EmployeeInvitationDto.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      throw Exception(response.message ?? 'Failed to load invitations');
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.getPendingInvitations error: $e');
      rethrow;
    }
  }

  Future<void> sendInvitationReply(String ownerId, bool isAccepted, String employeeName) async {
    try {
      await _apiClient.post(
        ApiEndpoints.invitationReplyNotification,
        body: {
          'ownerUserId': ownerId,
          'isAccepted': isAccepted,
          'employeeName': employeeName,
        },
      );
    } catch (e) {
      debugPrint('EmployeeApiService.sendInvitationReply error: $e');
    }
  }

  Future<void> acceptInvitation(int hireId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.acceptEmployeeInvitation(hireId),
      );

      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to accept invitation');
      }
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.acceptInvitation error: $e');
      rethrow;
    }
  }

  Future<void> rejectInvitation(int hireId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.rejectEmployeeInvitation(hireId),
      );

      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to reject invitation');
      }
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.rejectInvitation error: $e');
      rethrow;
    }
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteEmployee(employeeId),
      );

      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to update employee status');
      }
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.deleteEmployee error: $e');
      rethrow;
    }
  }
}
