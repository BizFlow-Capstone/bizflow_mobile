import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/location_entity.dart';

class LocationLocalMapper {
  const LocationLocalMapper._();

  static LocationEntity toEntity(LocationsTableData row) {
    List<String> employeeIds = const [];
    try {
      final decoded = jsonDecode(row.employeeIdsJson);
      if (decoded is List) {
        employeeIds = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return LocationEntity(
      id: row.id,
      name: row.name,
      address: row.address,
      district: row.district,
      city: row.city,
      phone: row.phone,
      isActive: row.isActive,
      ownerName: row.ownerName,
      ownerProfileId: row.ownerProfileId,
      taxCode: row.taxCode,
      employeeIds: employeeIds,
      isOwner: row.isOwner,
    );
  }

  static LocationsTableCompanion toCompanion(
    LocationEntity entity, {
    required String? businessId,
    required int cachedAtEpoch,
  }) {
    return LocationsTableCompanion(
      id: Value(entity.id),
      businessId: Value(businessId),
      name: Value(entity.name),
      address: Value(entity.address),
      district: Value(entity.district),
      city: Value(entity.city),
      phone: Value(entity.phone),
      isActive: Value(entity.isActive),
      ownerName: Value(entity.ownerName),
      ownerProfileId: Value(entity.ownerProfileId),
      taxCode: Value(entity.taxCode),
      employeeIdsJson: Value(jsonEncode(entity.employeeIds)),
      isOwner: Value(entity.isOwner),
      updatedAtEpoch: Value(DateTime.now().millisecondsSinceEpoch),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }
}
