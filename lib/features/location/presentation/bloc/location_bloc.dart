import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../employee/data/employee_repository.dart';
import '../../../employee/domain/entities/employee_entity.dart';
import '../../data/location_repository.dart';
import '../../data/models/location_dto.dart';
import '../../domain/entities/location_entity.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../../../../core/network/api_error_message_parser.dart';

/// Location BLoC
/// Quản lý logic của tất cả các thao tác liên quan đến địa điểm kinh doanh
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository repository;
  final EmployeeRepository employeeRepository;

  LocationBloc({required this.repository, required this.employeeRepository})
    : super(const LocationInitial()) {
    on<LoadLocationsRequested>(_onLoadLocationsRequested);
    on<RestoreLocationsRequested>(_onRestoreLocationsRequested);
    on<ToggleLocationStatusRequested>(_onToggleLocationStatusRequested);
    on<AddLocationRequested>(_onAddLocationRequested);
    on<EditLocationRequested>(_onEditLocationRequested);
    on<DeleteLocationRequested>(_onDeleteLocationRequested);
    on<LoadLocationEmployeesRequested>(_onLoadLocationEmployeesRequested);
    on<AddEmployeeToLocationFromTabRequested>(_onAddEmployeeToLocationFromTab);
    on<RemoveEmployeeFromTabRequested>(_onRemoveEmployeeFromTab);
    on<SaveLocationEmployeesRequested>(_onSaveLocationEmployees);
    on<RemoveEmployeeFromLocationRequested>(
      _onRemoveEmployeeFromLocationRequested,
    );
    on<ResetLocations>(_onResetLocations);
  }

  // Cache locations in memory
  List<LocationEntity> _locations = [];

  List<LocationEntity> get currentLocations => List.unmodifiable(_locations);

  // Track employee IDs for current location (updated locally after add)
  List<String> _currentLocationEmployeeIds = [];

  Future<List<LocationEntity>> _refreshLocations() async {
    // Fetch both owned and hired locations
    // Use catchError to ensure that if one fails (e.g. 403 on owned for an employee),
    // we still get the data from the other.
    debugPrint('LocationBloc: refreshing locations...');
    final results = await Future.wait([
      repository.getMyOwnedLocations().catchError((e) {
        debugPrint('LocationBloc: getMyOwnedLocations failed: $e');
        throw e;
      }),
      repository.getWorkAtLocations().catchError((e) {
        debugPrint('LocationBloc: getWorkAtLocations failed: $e');
        throw e;
      }),
    ]);

    final owned = results[0];
    final hired = results[1];
    debugPrint(
      'LocationBloc: Owned count: ${owned.length}, Hired count: ${hired.length}',
    );

    // Tag owned locations with isOwner: true
    final ownedTagged = owned
        .map((loc) => loc.copyWith(isOwner: true))
        .toList();
    // Work-at locations: isOwner defaults to false; only override if not already owned
    final ownedIds = ownedTagged.map((l) => l.id).toSet();

    // Combine and remove duplicates — owned takes priority
    final List<LocationEntity> combined = [...ownedTagged];
    for (var loc in hired) {
      if (!ownedIds.contains(loc.id)) {
        combined.add(loc.copyWith(isOwner: false));
      }
    }

    _locations = combined;
    return combined;
  }

  Future<List<EmployeeEntity>> fetchAvailableEmployees() {
    return employeeRepository.getAvailableEmployees();
  }

  Future<void> _onLoadLocationsRequested(
    LoadLocationsRequested event,
    Emitter<LocationState> emit,
  ) async {
    if (_locations.isEmpty) {
      emit(const LocationLoading());
    } else {
      emit(LocationsLoaded(locations: List.from(_locations)));
    }

    if (event.useCache) {
      try {
        final localCached = await repository.getCachedLocations();
        if (localCached.isNotEmpty) {
          _locations = localCached;
          emit(LocationsLoaded(locations: localCached));
        }
      } catch (e) {
        debugPrint('LocationBloc: Drift cache read failed: $e');
      }
    }

    try {
      final data = await _refreshLocations();
      debugPrint(
        'LocationBloc: Emitting LocationsLoaded with ${data.length} locations',
      );
      unawaited(repository.saveCachedLocations(data));
      emit(LocationsLoaded(locations: data));
    } catch (error) {
      if (_locations.isEmpty) {
        emit(LocationFailure(message: ApiErrorMessageParser.parse(error)));
      }
    }
  }

  /// Restore cached locations (instant, no API call)
  void _onRestoreLocationsRequested(
    RestoreLocationsRequested event,
    Emitter<LocationState> emit,
  ) {
    if (_locations.isNotEmpty) {
      emit(LocationsLoaded(locations: List.from(_locations)));
    } else {
      // Fallback: reload from API if cache is empty
      add(const LoadLocationsRequested());
    }
  }

  Future<void> _onToggleLocationStatusRequested(
    ToggleLocationStatusRequested event,
    Emitter<LocationState> emit,
  ) async {
    final targetIndex = _locations.indexWhere(
      (loc) => loc.id == event.locationId,
    );
    if (targetIndex == -1) {
      emit(
        const LocationFailure(
          message: 'Không tìm thấy địa điểm để cập nhật trạng thái.',
        ),
      );
      if (_locations.isNotEmpty) {
        emit(LocationsLoaded(locations: List.from(_locations)));
      }
      return;
    }

    final target = _locations[targetIndex];
    final previousIsActive = target.isActive;
    final activeCount = _locations.where((loc) => loc.isActive).length;
    final isDeactivatingLastActive =
        target.isActive && !event.isActive && activeCount <= 1;
    if (isDeactivatingLastActive) {
      emit(
        const LocationFailure(
          message:
              'Cần tối thiểu 1 địa điểm đang hoạt động, không thể tắt hết.',
        ),
      );
      emit(LocationsLoaded(locations: List.from(_locations)));
      return;
    }

    // Optimistic update: reflect the target state immediately for snappy UX.
    _locations[targetIndex] = target.copyWith(isActive: event.isActive);
    emit(LocationToggleInProgress(locationId: event.locationId));

    try {
      // Call API to update status (only returns success/fail)
      final success = await repository.updateLocationStatus(
        locationId: event.locationId,
        isActive: event.isActive,
      );

      if (success) {
        // Confirm with fresh server state to avoid stale UI/toast mismatch.
        final refreshed = await _refreshLocations();
        await repository.saveCachedLocations(refreshed);

        final refreshedIndex = refreshed.indexWhere(
          (loc) => loc.id == event.locationId,
        );
        if (refreshedIndex == -1) {
          emit(
            const LocationFailure(
              message: 'Không tìm thấy địa điểm sau khi cập nhật trạng thái.',
            ),
          );
          emit(LocationsLoaded(locations: List.from(_locations)));
          return;
        }

        final refreshedLocation = refreshed[refreshedIndex];
        if (refreshedLocation.isActive != event.isActive) {
          emit(
            const LocationFailure(
              message:
                  'Trạng thái địa điểm chưa được cập nhật trên hệ thống. Vui lòng thử lại.',
            ),
          );
          emit(LocationsLoaded(locations: List.from(_locations)));
          return;
        }

        emit(LocationToggleSuccess(updatedLocation: refreshedLocation));
        emit(LocationsLoaded(locations: List.from(_locations)));
        return;
      }

      _locations[targetIndex] = target.copyWith(isActive: previousIsActive);
      emit(
        const LocationFailure(
          message: 'Không thể cập nhật trạng thái địa điểm. Vui lòng thử lại.',
        ),
      );
      if (_locations.isNotEmpty) {
        emit(LocationsLoaded(locations: List.from(_locations)));
      }
    } catch (e) {
      _locations[targetIndex] = target.copyWith(isActive: previousIsActive);
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
      if (_locations.isNotEmpty) {
        emit(LocationsLoaded(locations: List.from(_locations)));
      }
    }
  }

  Future<void> _onAddLocationRequested(
    AddLocationRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationAddInProgress());
    try {
      final request = CreateLocationRequestDto(
        name: event.name,
        address: event.address,
        district: event.district,
        city: event.city,
        phone: event.phone,
        taxCode: event.taxCode,
        employeeIds: event.employeeIds,
      );

      final newLocation = await repository.createLocation(request);

      final refreshed = await _refreshLocations();
      final createdLocation = refreshed.firstWhere(
        (loc) => loc.id == newLocation.id,
        orElse: () => newLocation,
      );

      await repository.saveCachedLocations(refreshed);

      emit(LocationAddSuccess(newLocation: createdLocation));
      emit(LocationsLoaded(locations: List.from(refreshed)));
    } catch (e) {
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onEditLocationRequested(
    EditLocationRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationEditInProgress(locationId: event.locationId));
    try {
      // Call API to update location information
      final request = UpdateLocationRequestDto(
        name: event.name,
        address: event.address,
        district: event.district,
        city: event.city,
        phone: event.phone,
        taxCode: event.taxCode,
      );

      await repository.updateLocation(
        locationId: event.locationId,
        request: request,
      );

      // Find the original location to get currently assigned employees
      final originalLocation = _locations.firstWhere(
        (loc) => loc.id == event.locationId,
        orElse: () => LocationEntity(
          id: event.locationId,
          name: '',
          address: '',
          district: '',
          city: '',
          phone: '',
          isActive: false,
          ownerName: '',
          employeeIds: [],
        ),
      );

      // Only send employee IDs that are NEW (not already assigned)
      final currentEmployeeIds = originalLocation.employeeIds;
      final newEmployeeIds = event.employeeIds
          .where((id) => !currentEmployeeIds.contains(id))
          .toList();

      if (newEmployeeIds.isNotEmpty) {
        await repository.addEmployeesToLocation(
          locationId: event.locationId,
          employeeIds: newEmployeeIds,
        );
      }

      // Update local cache with new location data (no API call needed)
      final updatedLocation = LocationEntity(
        id: event.locationId,
        name: event.name,
        address: event.address,
        district: event.district,
        city: event.city,
        phone: event.phone,
        isActive: originalLocation.isActive,
        ownerName: originalLocation.ownerName,
        taxCode: event.taxCode,
        employeeIds: originalLocation.employeeIds + newEmployeeIds,
      );

      // Update local memory cache
      final index = _locations.indexWhere((loc) => loc.id == event.locationId);
      if (index != -1) {
        _locations[index] = updatedLocation;
      }

      await repository.saveCachedLocations(_locations);

      emit(LocationEditSuccess(updatedLocation: updatedLocation));
      emit(LocationsLoaded(locations: List.from(_locations)));
    } catch (e) {
      debugPrint('Edit location error: $e');
      emit(LocationFailure(message: e.toString()));
    }
  }

  Future<void> _onDeleteLocationRequested(
    DeleteLocationRequested event,
    Emitter<LocationState> emit,
  ) async {
    LocationEntity? target;
    for (final location in _locations) {
      if (location.id == event.locationId) {
        target = location;
        break;
      }
    }

    if (target == null) {
      emit(const LocationFailure(message: 'Không tìm thấy địa điểm để xóa.'));
      if (_locations.isNotEmpty) {
        emit(LocationsLoaded(locations: List.from(_locations)));
      }
      return;
    }

    if (_locations.length <= 1) {
      emit(
        const LocationFailure(
          message:
              'Phải có tối thiểu 1 địa điểm, không thể xóa địa điểm cuối cùng.',
        ),
      );
      emit(LocationsLoaded(locations: List.from(_locations)));
      return;
    }

    final activeCount = _locations.where((loc) => loc.isActive).length;
    final isDeletingLastActive = target.isActive && activeCount <= 1;
    if (isDeletingLastActive) {
      emit(
        const LocationFailure(
          message:
              'Cần tối thiểu 1 địa điểm đang hoạt động, không thể xóa địa điểm hoạt động cuối cùng.',
        ),
      );
      emit(LocationsLoaded(locations: List.from(_locations)));
      return;
    }

    emit(LocationDeleteInProgress(locationId: event.locationId));
    try {
      await repository.deleteLocation(event.locationId);

      // Refresh locations list
      add(const LoadLocationsRequested());

      emit(LocationDeleteSuccess(locationId: event.locationId));
    } catch (e) {
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
      if (_locations.isNotEmpty) {
        emit(LocationsLoaded(locations: List.from(_locations)));
      }
    }
  }

  /// Load employees assigned to a specific location
  /// Uses employeeIds from LocationEntity + myEmployees API to build lists
  Future<void> _onLoadLocationEmployeesRequested(
    LoadLocationEmployeesRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      // Fetch assigned employees from location API
      final assignedEmployees = await repository.getLocationEmployees(
        locationId: event.locationId,
      );

      // Update local tracking list with assigned employee IDs
      _currentLocationEmployeeIds = assignedEmployees.map((e) => e.id).toList();

      // Fetch all hired employees
      final allEmployees = await employeeRepository.getAvailableEmployees();

      emit(
        LocationEmployeesLoaded(
          locationEmployees: assignedEmployees,
          allEmployees: allEmployees,
        ),
      );
    } catch (e) {
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Add a single employee to location from employee tab (LOCAL only, no API call)
  Future<void> _onAddEmployeeToLocationFromTab(
    AddEmployeeToLocationFromTabRequested event,
    Emitter<LocationState> emit,
  ) async {
    try {
      // Update local list only
      _currentLocationEmployeeIds.add(event.employeeId);

      // Re-filter and emit updated state
      final allEmployees = await employeeRepository.getAvailableEmployees();
      final locationEmployees = allEmployees
          .where((e) => _currentLocationEmployeeIds.contains(e.id))
          .toList();

      emit(
        LocationEmployeesLoaded(
          locationEmployees: locationEmployees,
          allEmployees: allEmployees,
        ),
      );
    } catch (e) {
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Remove a single employee from location tab (LOCAL only, no API call)
  Future<void> _onRemoveEmployeeFromTab(
    RemoveEmployeeFromTabRequested event,
    Emitter<LocationState> emit,
  ) async {
    try {
      // Update local list only
      _currentLocationEmployeeIds.remove(event.employeeId);

      // Re-filter and emit updated state
      final allEmployees = await employeeRepository.getAvailableEmployees();
      final locationEmployees = allEmployees
          .where((e) => _currentLocationEmployeeIds.contains(e.id))
          .toList();

      emit(
        LocationEmployeesLoaded(
          locationEmployees: locationEmployees,
          allEmployees: allEmployees,
        ),
      );
    } catch (e) {
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onSaveLocationEmployees(
    SaveLocationEmployeesRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      await repository.addEmployeesToLocation(
        locationId: event.locationId,
        employeeIds: _currentLocationEmployeeIds,
      );

      emit(const SaveLocationEmployeesSuccess());

      // Reload employees to confirm server state
      final allEmployees = await employeeRepository.getAvailableEmployees();
      final locationEmployees = allEmployees
          .where((e) => _currentLocationEmployeeIds.contains(e.id))
          .toList();

      emit(
        LocationEmployeesLoaded(
          locationEmployees: locationEmployees,
          allEmployees: allEmployees,
        ),
      );
    } catch (e) {
      emit(LocationFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onRemoveEmployeeFromLocationRequested(
    RemoveEmployeeFromLocationRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      await repository.removeEmployeeFromLocation(
        locationId: event.locationId,
        employeeId: event.employeeId,
      );

      // Refresh employee list for this location
      add(
        LoadLocationEmployeesRequested(
          locationId: event.locationId,
          currentEmployeeIds: _currentLocationEmployeeIds,
        ),
      );

      emit(
        RemoveEmployeeFromLocationSuccess(
          locationId: event.locationId,
          employeeId: event.employeeId,
        ),
      );
    } catch (e) {
      emit(LocationFailure(message: e.toString()));
    }
  }

  Future<void> _onResetLocations(
    ResetLocations event,
    Emitter<LocationState> emit,
  ) async {
    _locations = [];
    _currentLocationEmployeeIds = [];
    try {
      await repository.clearCachedLocations();
    } catch (_) {
      // Database may already be closing during logout — safe to ignore.
    }
    emit(const LocationInitial());
  }
}
