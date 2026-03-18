import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../employee/data/models/employee_dto.dart';
import 'models/location_dto.dart';

/// Location API Service - Handles direct API communication
///
/// Responsibilities:
/// 1. Make HTTP requests via ApiClient
/// 2. Parse raw responses to DTOs
/// 3. Handle API-specific errors
/// 4. Return DTOs to Repository
class LocationApiService {
  final ApiClient _apiClient;

  LocationApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  String get _currentBaseUrl => AppConfig.baseUrl;

  /// Get business locations owned by current user
  ///
  /// API: GET /api/location/me/owned
  /// Returns: LocationResponseDto
  /// Throws: Exception with user-friendly message
  Future<LocationResponseDto> getMyOwnedLocations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myOwnedLocations);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Success: ${response.isSuccess}');
      debugPrint('API Response Data Type: ${response.data.runtimeType}');
      debugPrint('API Response Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        // Check if response.data is Map
        if (response.data is! Map<String, dynamic>) {
          throw Exception(
            'Response không đúng format\n\n'
            'Expected: Map<String, dynamic>\n'
            'Got: ${response.data.runtimeType}\n'
            'Data: ${response.data}',
          );
        }

        // Parse raw JSON to DTO
        return LocationResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(response.message ?? 'Failed to load locations');
      }
    } on ApiException catch (e) {
      // Transform ApiException to domain exception with user-friendly messages
      if (e.statusCode == -1) {
        throw Exception(
          'No network connection\n\n'
          'Check:\n'
          '• Is backend running?\n'
          '• URL: $_currentBaseUrl',
        );
      } else if (e.statusCode == -2) {
        throw Exception(
          'Connection timeout\n\n'
          'Backend did not respond within 30 seconds',
        );
      } else if (e.statusCode == -3) {
        // HttpException or connection error
        throw Exception(
          'Backend connection error\n\n'
          '${e.message}\n\n'
          'Solutions:\n'
          '1. Check backend is running: dotnet run\n'
          '2. Ensure backend port is not blocked\n'
          '3. Hot restart app (press R)\n'
          '4. Check URL: $_currentBaseUrl',
        );
      } else if (e.statusCode == 401) {
        throw Exception('Session expired\n\nPlease login again');
      } else if (e.statusCode == 404) {
        throw Exception('Data not found');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.getMyOwnedLocations error: $e');
      rethrow;
    }
  }

  /// Get locations where user works at
  ///
  /// API: GET /api/location/work-at-locations
  /// Returns: LocationResponseDto
  Future<LocationResponseDto> getWorkAtLocations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.workAtLocations);

      if (response.isSuccess && response.data != null) {
        return LocationResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(response.message ?? 'Failed to load work locations');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Session expired');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.getWorkAtLocations error: $e');
      rethrow;
    }
  }

  /// Create new location
  ///
  /// API: POST /api/location/create
  /// Body: CreateLocationRequestDto
  Future<LocationDto> createLocation(CreateLocationRequestDto request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createLocation,
        body: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return LocationDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.message ?? 'Failed to create location');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        String detail = e.message;
        final data = e.data;
        if (data is Map<String, dynamic>) {
          final errors = data['errors'];
          if (errors is Map<String, dynamic>) {
            final errorMessage = errors['message']?.toString();
            final errorException = errors['exception']?.toString();
            if (errorMessage != null && errorMessage.isNotEmpty) {
              detail = '$detail | $errorMessage';
            }
            if (errorException != null && errorException.isNotEmpty) {
              detail = '$detail ($errorException)';
            }
          }
        }
        throw Exception('Invalid data: $detail');
      }
      throw Exception('Error creating location: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.createLocation error: $e');
      rethrow;
    }
  }

  /// Update location status
  ///
  /// API: PUT /api/location/me/owned/{id}/status
  /// Body: { "isActive": bool }
  /// Returns: { success, message }
  Future<bool> updateLocationStatus({
    required String locationId,
    required bool isActive,
  }) async {
    try {
      debugPrint('=== UPDATE STATUS REQUEST ===');
      debugPrint('LocationId: $locationId (Type: ${locationId.runtimeType})');
      debugPrint('isActive: $isActive');
      debugPrint('URL: ${ApiEndpoints.updateLocationStatus(locationId)}');

      final body = UpdateStatusRequestDto(isActive: isActive).toJson();
      debugPrint('Request Body: $body');

      final response = await _apiClient.patch(
        ApiEndpoints.updateLocationStatus(locationId),
        body: body,
      );

      debugPrint('=== UPDATE STATUS RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Success: ${response.isSuccess}');
      debugPrint('Response Message: ${response.message}');
      debugPrint('Response Data: ${response.data}');

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to update status');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: You are not the owner');
      } else if (e.statusCode == 404) {
        throw Exception('Location not found');
      } else if (e.statusCode == 307) {
        throw Exception(
          'Server redirect error (307) - Check backend configuration and URL format',
        );
      }
      throw Exception('Error updating status: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.updateLocationStatus error: $e');
      rethrow;
    }
  }

  /// Update location information
  ///
  /// API: PUT /api/location/me/owned/{id}
  /// Body: UpdateLocationRequestDto
  /// Response: { success, message } - Backend returns success only, need to refetch for updated data
  Future<LocationDto> updateLocation({
    required String locationId,
    required UpdateLocationRequestDto request,
  }) async {
    try {
      debugPrint('=== UPDATE LOCATION REQUEST ===');
      debugPrint('LocationId: $locationId (Type: ${locationId.runtimeType})');
      debugPrint('URL: ${ApiEndpoints.updateLocation(locationId)}');
      final body = request.toJson();
      debugPrint('Request Body: $body');

      final response = await _apiClient.put(
        ApiEndpoints.updateLocation(locationId),
        body: body,
      );

      debugPrint('=== UPDATE LOCATION RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Success: ${response.isSuccess}');
      debugPrint('Response Message: ${response.message}');
      debugPrint('Response Data: ${response.data}');

      if (response.isSuccess) {
        // Backend returns success/message only, return dummy object for now
        // The list will be refetched in BLoC after this call
        return LocationDto(
          id: int.tryParse(locationId) ?? 0,
          name: request.name,
          address: request.address,
          district: request.district,
          city: request.city,
          phone: request.phone,
          isActive: true,
          ownerName: '',
          taxCode: request.taxCode,
          employeeIds: [],
        );
      } else {
        throw Exception(response.message ?? 'Failed to update location');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw Exception('Invalid data: ${e.message}');
      } else if (e.statusCode == 404) {
        throw Exception('Location not found');
      } else if (e.statusCode == 403) {
        throw Exception('Permission denied: You are not the owner');
      } else if (e.statusCode == 307) {
        throw Exception(
          'Server redirect error (307) - Check backend configuration',
        );
      }
      throw Exception('Error updating location: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.updateLocation error: $e');
      rethrow;
    }
  }

  /// Add employees to location
  ///
  /// API: POST /api/location/{locationId}/employees
  /// Body: List<String> (employee user IDs)
  /// The API expects: ["uuid1", "uuid2", ...]
  Future<void> addEmployeesToLocation({
    required String locationId,
    required List<String> employeeIds,
  }) async {
    try {
      debugPrint('=== ADD EMPLOYEES REQUEST ===');
      debugPrint('LocationId: $locationId (Type: ${locationId.runtimeType})');
      debugPrint('URL: ${ApiEndpoints.addEmployeesToLocation(locationId)}');
      debugPrint('Employee IDs: $employeeIds');
      debugPrint('Employee IDs Count: ${employeeIds.length}');
      debugPrint('Request Body Type: ${employeeIds.runtimeType}');

      final response = await _apiClient.post(
        ApiEndpoints.addEmployeesToLocation(locationId),
        body: employeeIds,
      );

      debugPrint('=== ADD EMPLOYEES RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Success: ${response.isSuccess}');
      debugPrint('Response Message: ${response.message}');
      debugPrint('Response Data: ${response.data}');

      if (response.isSuccess) {
        return;
      } else {
        throw Exception(response.message ?? 'Failed to add employees');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 400) {
        throw Exception('Invalid request: ${e.message}');
      } else if (e.statusCode == 404) {
        throw Exception('Location or employees not found');
      } else if (e.statusCode == 403) {
        throw Exception('Permission denied: You are not the owner');
      } else if (e.statusCode == 307) {
        throw Exception(
          'Server redirect error (307) - Check backend node configuration',
        );
      }
      throw Exception('Error adding employees: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.addEmployeesToLocation error: $e');
      rethrow;
    }
  }

  /// Get employees assigned to a location
  ///
  /// API: GET /api/location/{locationId}/employees
  /// Returns: List<EmployeeDto>
  Future<List<EmployeeDto>> getLocationEmployees({
    required String locationId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getLocationEmployees(locationId),
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final employeeData = data['data'] as Map<String, dynamic>?;
        final employeeList = employeeData != null
            ? (employeeData['employees'] as List<dynamic>? ?? [])
            : [];

        return employeeList
            .map((item) => EmployeeDto.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          response.message ?? 'Failed to load location employees',
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('🔒 Session expired');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.getLocationEmployees error: $e');
      rethrow;
    }
  }

  /// Delete a business location
  ///
  /// API: DELETE /api/location/me/owned/{id}
  /// Returns: String (message from server)
  Future<String> deleteLocation(String locationId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteLocation(locationId),
      );

      if (response.isSuccess) {
        return response.message ?? 'Location deleted successfully';
      } else {
        throw Exception(response.message ?? 'Failed to delete location');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception('Permission denied: You are not the owner');
      } else if (e.statusCode == 404) {
        throw Exception('Location not found');
      }
      throw Exception('Error deleting location: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.deleteLocation error: $e');
      rethrow;
    }
  }

  /// Remove an employee from a location
  ///
  /// API: DELETE /api/location/{locationId}/employees/{employeeId}
  /// Returns: String (message from server)
  Future<String> removeEmployeeFromLocation({
    required String locationId,
    required String employeeId,
  }) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.removeEmployeeFromLocation(locationId, employeeId),
      );

      if (response.isSuccess) {
        return response.message ?? 'Employee removed successfully';
      } else {
        throw Exception(response.message ?? 'Failed to remove employee');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception('Permission denied: You are not the owner');
      } else if (e.statusCode == 404) {
        throw Exception('Location or employee not found');
      }
      throw Exception('Error removing employee: ${e.message}');
    } catch (e) {
      debugPrint('LocationApiService.removeEmployeeFromLocation error: $e');
      rethrow;
    }
  }
}
