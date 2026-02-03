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
  final String district;
  final String city;
  final String phone;
  final String taxCode;
  final String managerId;
  final String managerName;
  final List<String> employeeIds;

  const AddLocationRequested({
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phone,
    required this.taxCode,
    required this.managerId,
    required this.managerName,
    required this.employeeIds,
  });

  @override
  List<Object?> get props => [name, address, district, city, phone, taxCode, managerId, managerName, employeeIds];
}

/// Edit location
class EditLocationRequested extends LocationEvent {
  final String locationId;
  final String name;
  final String address;
  final String district;
  final String city;
  final String phone;
  final String taxCode;
  final String managerId;
  final String managerName;
  final List<String> employeeIds;

  const EditLocationRequested({
    required this.locationId,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phone,
    required this.taxCode,
    required this.managerId,
    required this.managerName,
    required this.employeeIds,
  });

  @override
  List<Object?> get props => [locationId, name, address, district, city, phone, taxCode, managerId, managerName, employeeIds];
}

/// Delete location
class DeleteLocationRequested extends LocationEvent {
  final String locationId;

  const DeleteLocationRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}
