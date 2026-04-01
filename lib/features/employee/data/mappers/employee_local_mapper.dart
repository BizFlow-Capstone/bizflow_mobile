import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeeLocalMapper {
  static EmployeeEntity toEntity(EmployeesTableData row) {
    return EmployeeEntity(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      status: _parseStatus(row.status),
      isActive: row.isActive,
      employmentStatus: row.employmentStatus,
      startedAt: row.startedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.startedAtEpoch!),
      endedAt: row.endedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.endedAtEpoch!),
      assignedBusinessId: row.businessId,
      assignedLocationIds: _decodeStringList(row.assignedLocationIdsJson),
      assignedLocationNames: _decodeStringList(row.assignedLocationNamesJson),
    );
  }

  static EmployeesTableCompanion toCompanion(
    EmployeeEntity entity, {
    required String businessId,
    required int cachedAtEpoch,
  }) {
    return EmployeesTableCompanion.insert(
      id: entity.id,
      businessId: businessId,
      name: entity.name,
      phone: Value(entity.phone),
      email: Value(entity.email),
      status: Value(entity.status.name),
      isActive: Value(entity.isActive),
      employmentStatus: Value(entity.employmentStatus),
      startedAtEpoch: Value(entity.startedAt?.millisecondsSinceEpoch),
      endedAtEpoch: Value(entity.endedAt?.millisecondsSinceEpoch),
      assignedLocationIdsJson: Value(jsonEncode(entity.assignedLocationIds)),
      assignedLocationNamesJson: Value(
        jsonEncode(entity.assignedLocationNames),
      ),
      cachedAtEpoch: cachedAtEpoch,
    );
  }

  static EmployeeStatus _parseStatus(String raw) {
    return EmployeeStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => EmployeeStatus.active,
    );
  }

  static List<String> _decodeStringList(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed.map((item) => item.toString()).toList();
    } catch (_) {
      return const [];
    }
  }
}
