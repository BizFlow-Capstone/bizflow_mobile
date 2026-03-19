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

  /// Get employees available for assignment
  ///
  /// API: GET /api/my-employee/employees
  /// Returns: List<EmployeeDto>
  Future<List<EmployeeDto>> getMyEmployees() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myEmployees);

      if (response.isSuccess && response.data != null) {
        final dto = EmployeeResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        return dto.employees;
      } else {
        throw Exception(response.message ?? 'Failed to load employees');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('🔒 Session expired');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.getMyEmployees error: $e');
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
        return list
            .map((item) => EmployeeDto.fromJson(item as Map<String, dynamic>))
            .toList();
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
        throw Exception(response.message ?? 'Failed to delete employee');
      }
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('EmployeeApiService.deleteEmployee error: $e');
      rethrow;
    }
  }
}
