import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/location_entity.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

/// Location BLoC
/// Quản lý logic của tất cả các thao tác liên quan đến địa điểm kinh doanh
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(const LocationInitial()) {
    on<LoadLocationsRequested>(_onLoadLocationsRequested);
    on<ToggleLocationStatusRequested>(_onToggleLocationStatusRequested);
    on<AddLocationRequested>(_onAddLocationRequested);
    on<EditLocationRequested>(_onEditLocationRequested);
    on<DeleteLocationRequested>(_onDeleteLocationRequested);
  }

  // Mock data - thay bằng repository call
  final List<LocationEntity> _locations = [
    LocationEntity(
      id: '1',
      name: 'Kho Quận 1',
      address: '123 Nguyễn Huệ, Quận 1, TP.HCM',
      managerId: 'mgr1',
      managerName: 'Nguyễn Văn A',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LocationEntity(
      id: '2',
      name: 'Kho Thủ Đức',
      address: '456 Võ Văn Ngân, Thủ Đức, TP.HCM',
      managerId: 'mgr2',
      managerName: 'Trần Thị B',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> _onLoadLocationsRequested(
    LoadLocationsRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      // TODO: Call repository to get locations
      await Future.delayed(const Duration(milliseconds: 500));
      emit(LocationsLoaded(locations: _locations));
    } catch (e) {
      emit(LocationFailure(message: e.toString()));
    }
  }

  Future<void> _onToggleLocationStatusRequested(
    ToggleLocationStatusRequested event,
    Emitter<LocationState> emit,
  ) async {
    try {
      // Cập nhật local state ngay
      final index = _locations.indexWhere((loc) => loc.id == event.locationId);
      if (index != -1) {
        _locations[index] = _locations[index].copyWith(isActive: event.isActive);

        // Emit LocationToggleSuccess trước để BlocListener capture
        emit(LocationToggleSuccess(updatedLocation: _locations[index]));

        // Sau đó emit LocationsLoaded để UI update
        emit(LocationsLoaded(locations: List.from(_locations)));
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
      // TODO: Call repository to add location
      await Future.delayed(const Duration(milliseconds: 500));

      final newLocation = LocationEntity(
        id: DateTime.now().toString(),
        name: event.name,
        address: event.address,
        managerId: event.managerId,
        managerName: event.managerName,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _locations.add(newLocation);
      emit(LocationAddSuccess(newLocation: newLocation));
      emit(LocationsLoaded(locations: _locations));
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
      // TODO: Call repository to edit location
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _locations.indexWhere((loc) => loc.id == event.locationId);
      if (index != -1) {
        _locations[index] = _locations[index].copyWith(
          name: event.name,
          address: event.address,
          managerId: event.managerId,
          managerName: event.managerName,
          updatedAt: DateTime.now(),
        );
        emit(LocationEditSuccess(updatedLocation: _locations[index]));
        emit(LocationsLoaded(locations: _locations));
      }
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
