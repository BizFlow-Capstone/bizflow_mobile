import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/locations_table.dart';

part 'locations_dao.g.dart';

@DriftAccessor(tables: [LocationsTable])
class LocationsDao extends DatabaseAccessor<AppDatabase>
    with _$LocationsDaoMixin {
  LocationsDao(super.db);

  Future<List<LocationsTableData>> getByBusinessId(String? businessId) {
    final query = select(locationsTable);
    if (businessId == null || businessId.isEmpty) {
      query.where((tbl) => tbl.businessId.isNull());
    } else {
      query.where((tbl) => tbl.businessId.equals(businessId));
    }
    return query.get();
  }

  Stream<List<LocationsTableData>> watchByBusinessId(String? businessId) {
    final query = select(locationsTable);
    if (businessId == null || businessId.isEmpty) {
      query.where((tbl) => tbl.businessId.isNull());
    } else {
      query.where((tbl) => tbl.businessId.equals(businessId));
    }
    return query.watch();
  }

  Future<void> replaceForBusiness(
    String? businessId,
    List<LocationsTableCompanion> rows,
  ) async {
    await transaction(() async {
      final deleteQuery = delete(locationsTable);
      if (businessId == null || businessId.isEmpty) {
        deleteQuery.where((tbl) => tbl.businessId.isNull());
      } else {
        deleteQuery.where((tbl) => tbl.businessId.equals(businessId));
      }
      await deleteQuery.go();

      if (rows.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(locationsTable, rows);
        });
      }
    });
  }

  Future<void> upsertAll(List<LocationsTableCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(locationsTable, rows);
    });
  }

  Future<void> clearAll() => delete(locationsTable).go();
}
