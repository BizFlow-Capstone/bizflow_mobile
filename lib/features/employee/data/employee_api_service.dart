import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/employee_dto.dart';

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
      final response = await _apiClient.get(
        ApiEndpoints.myEmployees,
      );

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
}
