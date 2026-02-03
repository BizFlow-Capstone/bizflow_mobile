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

  LocationBloc({
    required this.repository,
    required this.employeeRepository,
  }) : super(const LocationInitial()) {
    on<LoadLocationsRequested>(_onLoadLocationsRequested);
    on<ToggleLocationStatusRequested>(_onToggleLocationStatusRequested);
    on<AddLocationRequested>(_onAddLocationRequested);
    on<EditLocationRequested>(_onEditLocationRequested);
    on<DeleteLocationRequested>(_onDeleteLocationRequested);
  }

  // Cache locations in memory
  List<LocationEntity> _locations = [];

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
        final index = _locations.indexWhere((loc) => loc.id == event.locationId);
        if (index != -1) {
          _locations[index] = _locations[index].copyWith(isActive: event.isActive);
          
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

      if (event.employeeIds.isNotEmpty) {
        await repository.addEmployeesToLocation(
          locationId: newLocation.id,
          employeeIds: event.employeeIds,
        );
      }

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
      // Call real API to update location
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

      // Refetch entire list to get correct data from backend
      final updatedList = await _refreshLocations();
      
      final updatedLocation = updatedList.firstWhere(
        (loc) => loc.id == event.locationId,
        orElse: () => updatedList.first,
      );
      
      emit(LocationEditSuccess(updatedLocation: updatedLocation));
      emit(LocationsLoaded(locations: List.from(updatedList)));
    } catch (e) {
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
}
