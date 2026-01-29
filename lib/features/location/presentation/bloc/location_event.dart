import 'package:equatable/equatable.dart';

/// Location Events
abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

/// Load all locations
class LoadLocationsRequested extends LocationEvent {
  const LoadLocationsRequested();
}

/// Toggle location active status
class ToggleLocationStatusRequested extends LocationEvent {
  final String locationId;
  final bool isActive;

  const ToggleLocationStatusRequested({
    required this.locationId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [locationId, isActive];
}

/// Add new location
class AddLocationRequested extends LocationEvent {
  final String name;
  final String address;
  final String managerId;
  final String managerName;

  const AddLocationRequested({
    required this.name,
    required this.address,
    required this.managerId,
    required this.managerName,
  });

  @override
  List<Object?> get props => [name, address, managerId, managerName];
}

/// Edit location
class EditLocationRequested extends LocationEvent {
  final String locationId;
  final String name;
  final String address;
  final String managerId;
  final String managerName;

  const EditLocationRequested({
    required this.locationId,
    required this.name,
    required this.address,
    required this.managerId,
    required this.managerName,
  });

  @override
  List<Object?> get props => [locationId, name, address, managerId, managerName];
}

/// Delete location
class DeleteLocationRequested extends LocationEvent {
  final String locationId;

  const DeleteLocationRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}
