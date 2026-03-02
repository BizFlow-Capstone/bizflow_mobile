import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../employee/data/employee_repository.dart';
import '../../../employee/domain/entities/employee_entity.dart';
import '../../data/location_repository.dart';
import '../../data/models/location_dto.dart';
import '../../domain/entities/location_entity.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

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
  }

  // Cache locations in memory
  List<LocationEntity> _locations = [];

  // Track employee IDs for current location (updated locally after add)
  List<String> _currentLocationEmployeeIds = [];

  Future<List<LocationEntity>> _refreshLocations() async {
    final locations = await repository.getMyOwnedLocations();
    _locations = locations;
    return locations;
  }

  Future<List<EmployeeEntity>> fetchAvailableEmployees() {
    return employeeRepository.getAvailableEmployees();
  }

  Future<void> _onLoadLocationsRequested(
    LoadLocationsRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      // Call API to get locations
      final locations = await _refreshLocations();
      emit(LocationsLoaded(locations: locations));
    } catch (e) {
      emit(LocationFailure(message: e.toString()));
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
    try {
      // Call API to update status (only returns success/fail)
      final success = await repository.updateLocationStatus(
        locationId: event.locationId,
        isActive: event.isActive,
      );

      if (success) {
        // Update local cache manually (backend doesn't return updated entity)
        final index = _locations.indexWhere(
          (loc) => loc.id == event.locationId,
        );
        if (index != -1) {
          _locations[index] = _locations[index].copyWith(
            isActive: event.isActive,
          );

          // Emit success event
          emit(LocationToggleSuccess(updatedLocation: _locations[index]));

          // Update UI
          emit(LocationsLoaded(locations: List.from(_locations)));
        }
      }
    } catch (e) {
      emit(LocationFailure(message: e.toString()));
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

      emit(LocationAddSuccess(newLocation: createdLocation));
      emit(LocationsLoaded(locations: List.from(refreshed)));
    } catch (e) {
      emit(LocationFailure(message: e.toString()));
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

      // Update cache
      final index = _locations.indexWhere((loc) => loc.id == event.locationId);
      if (index != -1) {
        _locations[index] = updatedLocation;
      }

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
    emit(LocationDeleteInProgress(locationId: event.locationId));
    try {
      // TODO: Call repository to delete location
      await Future.delayed(const Duration(milliseconds: 500));

      _locations.removeWhere((loc) => loc.id == event.locationId);
      emit(LocationDeleteSuccess(locationId: event.locationId));
      emit(LocationsLoaded(locations: _locations));
    } catch (e) {
      emit(LocationFailure(message: e.toString()));
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
      emit(LocationFailure(message: e.toString()));
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
      emit(LocationFailure(message: e.toString()));
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
      emit(LocationFailure(message: e.toString()));
    }
  }

  /// Save all employee assignments to server (batch API call)
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
      emit(LocationFailure(message: e.toString()));
    }
  }
}
