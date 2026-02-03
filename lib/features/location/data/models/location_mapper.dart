import 'location_dto.dart';
import '../../domain/entities/location_entity.dart';

/// Location Mapper - Converts between DTO and Entity
class LocationMapper {
  LocationMapper._();

  /// Convert DTO to Entity
  static LocationEntity toEntity(LocationDto dto) {
    return LocationEntity(
      id: dto.id.toString(),
      name: dto.name,
      address: dto.address,
      district: dto.district,
      city: dto.city,
      phone: dto.phone,
      isActive: dto.isActive,
      ownerName: dto.ownerName,
      taxCode: dto.taxCode,
      employeeIds: dto.employeeIds,
    );
  }

  /// Convert list of DTOs to list of Entities
  static List<LocationEntity> toEntityList(List<LocationDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Convert Entity to DTO (for create/update)
  static LocationDto toDto(LocationEntity entity) {
    return LocationDto(
      id: int.tryParse(entity.id) ?? 0,
      name: entity.name,
      address: entity.address,
      district: entity.district,
      city: entity.city,
      phone: entity.phone,
      isActive: entity.isActive,
      ownerName: entity.ownerName,
      taxCode: entity.taxCode,
      employeeIds: entity.employeeIds,
    );
  }
}
