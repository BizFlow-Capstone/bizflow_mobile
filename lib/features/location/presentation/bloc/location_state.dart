import 'package:equatable/equatable.dart';
import '../../../employee/domain/entities/employee_entity.dart';
import '../../domain/entities/location_entity.dart';

/// Location States
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationsLoaded extends LocationState {
  final List<LocationEntity> locations;

  const LocationsLoaded({required this.locations});

  @override
  List<Object?> get props => [locations];
}

class LocationToggleInProgress extends LocationState {
  final String locationId;

  const LocationToggleInProgress({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class LocationToggleSuccess extends LocationState {
  final LocationEntity updatedLocation;

  const LocationToggleSuccess({required this.updatedLocation});

  @override
  List<Object?> get props => [updatedLocation];
}

class LocationAddInProgress extends LocationState {
  const LocationAddInProgress();
}

class LocationAddSuccess extends LocationState {
  final LocationEntity newLocation;

  const LocationAddSuccess({required this.newLocation});

  @override
  List<Object?> get props => [newLocation];
}

class LocationEditInProgress extends LocationState {
  final String locationId;

  const LocationEditInProgress({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class LocationEditSuccess extends LocationState {
  final LocationEntity updatedLocation;

  const LocationEditSuccess({required this.updatedLocation});

  @override
  List<Object?> get props => [updatedLocation];
}

class LocationDeleteInProgress extends LocationState {
  final String locationId;

  const LocationDeleteInProgress({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class LocationDeleteSuccess extends LocationState {
  final String locationId;

  const LocationDeleteSuccess({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class LocationFailure extends LocationState {
  final String message;

  const LocationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Employees loaded for a specific location (employee tab)
class LocationEmployeesLoaded extends LocationState {
  final List<EmployeeEntity> locationEmployees;
  final List<EmployeeEntity> allEmployees;

  const LocationEmployeesLoaded({
    required this.locationEmployees,
    required this.allEmployees,
  });

  /// Employees not yet assigned to this location
  List<EmployeeEntity> get unassignedEmployees {
    final assignedIds = locationEmployees.map((e) => e.id).toSet();
    return allEmployees.where((e) => !assignedIds.contains(e.id)).toList();
  }

  @override
  List<Object?> get props => [locationEmployees, allEmployees];
}

/// Employee successfully added to location from tab
class AddEmployeeToLocationSuccess extends LocationState {
  const AddEmployeeToLocationSuccess();
}

/// Employees successfully saved to server (batch update)
class SaveLocationEmployeesSuccess extends LocationState {
  const SaveLocationEmployeesSuccess();
}
