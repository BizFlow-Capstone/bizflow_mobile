import 'package:flutter/material.dart';
import '../domain/entities/location_entity.dart';
import 'location_api_service.dart';
import 'models/location_dto.dart';
import 'models/location_mapper.dart';

/// Location Repository - Orchestrates data flow between BLoC and Service
///
/// Architecture:
/// BLoC → Repository → Service → ApiClient → Backend
///
/// Responsibilities:
/// 1. Receive requests from BLoC
/// 2. Call appropriate Service methods
/// 3. Handle business logic errors
/// 4. Map DTOs to Entities via Mapper
/// 5. Return domain entities to BLoC
class LocationRepository {
  final LocationApiService _service;

  LocationRepository({required LocationApiService service}) : _service = service;

  /// Get business locations owned by current user
  ///
  /// Flow:
  /// 1. Call Service.getMyOwnedLocations()
  /// 2. Receive LocationResponseDto
  /// 3. Map DTOs to Entities
  /// 4. Return List<LocationEntity>
  Future<List<LocationEntity>> getMyOwnedLocations() async {
    try {
      // Step 1: Call Service (Service handles API errors)
      final responseDto = await _service.getMyOwnedLocations();

      // Step 2: Map DTO to Entity
      final entities = LocationMapper.toEntityList(responseDto.data);

      return entities;
    } catch (e) {
      // Repository just logs and rethrows - Service already handled API errors
      debugPrint('LocationRepository.getMyOwnedLocations error: $e');
      rethrow;
    }
  }

  /// Get locations where user works at
  Future<List<LocationEntity>> getWorkAtLocations() async {
    try {
      final responseDto = await _service.getWorkAtLocations();
      final entities = LocationMapper.toEntityList(responseDto.data);
      return entities;
    } catch (e) {
      debugPrint('LocationRepository.getWorkAtLocations error: $e');
      rethrow;
    }
  }

  /// Create new location
  Future<LocationEntity> createLocation(CreateLocationRequestDto request) async {
    try {
      final dto = await _service.createLocation(request);
      return LocationMapper.toEntity(dto);
    } catch (e) {
      debugPrint('LocationRepository.createLocation error: $e');
      rethrow;
    }
  }

  /// Update location status
  /// Returns the updated status (not full entity, backend doesn't return it)
  Future<bool> updateLocationStatus({
    required String locationId,
    required bool isActive,
  }) async {
    try {
      final success = await _service.updateLocationStatus(
        locationId: locationId,
        isActive: isActive,
      );
      return success;
    } catch (e) {
      debugPrint('LocationRepository.updateLocationStatus error: $e');
      rethrow;
    }
  }

  /// Update location information
  Future<LocationEntity> updateLocation({
    required String locationId,
    required UpdateLocationRequestDto request,
  }) async {
    try {
      final dto = await _service.updateLocation(
        locationId: locationId,
        request: request,
      );
      return LocationMapper.toEntity(dto);
    } catch (e) {
      debugPrint('LocationRepository.updateLocation error: $e');
      rethrow;
    }
  }

  /// Add employees to location
  Future<void> addEmployeesToLocation({
    required String locationId,
    required List<String> employeeIds,
  }) async {
    try {
      await _service.addEmployeesToLocation(
        locationId: locationId,
        employeeIds: employeeIds,
      );
    } catch (e) {
      debugPrint('LocationRepository.addEmployeesToLocation error: $e');
      rethrow;
    }
  }
}
