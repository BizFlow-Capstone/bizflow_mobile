import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_state_table.dart';

part 'sync_state_dao.g.dart';

@DriftAccessor(tables: [SyncStateTable])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<void> upsert({
    required String resourceKey,
    required String businessId,
    required int lastSyncedAtEpoch,
    String? etag,
  }) {
    return into(syncStateTable).insertOnConflictUpdate(
      SyncStateTableCompanion.insert(
        resourceKey: resourceKey,
        businessId: Value(businessId),
        lastSyncedAtEpoch: lastSyncedAtEpoch,
        etag: Value(etag),
      ),
    );
  }

  Future<void> upsertAll(List<SyncStateTableCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(syncStateTable, rows);
    });
  }

  Future<SyncStateTableData?> getState({
    required String resourceKey,
    required String businessId,
  }) {
    return (select(syncStateTable)
          ..where((tbl) => tbl.resourceKey.equals(resourceKey))
          ..where((tbl) => tbl.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  Future<List<SyncStateTableData>> listByBusinessAndResourcePrefix({
    required String businessId,
    required String resourcePrefix,
  }) {
    return (select(syncStateTable)
          ..where((tbl) => tbl.businessId.equals(businessId))
          ..where((tbl) => tbl.resourceKey.like('$resourcePrefix%')))
        .get();
  }

  Future<void> deleteByBusinessAndResourceKeys({
    required String businessId,
    required List<String> resourceKeys,
  }) async {
    if (resourceKeys.isEmpty) return;
    await (delete(syncStateTable)
          ..where((tbl) => tbl.businessId.equals(businessId))
          ..where((tbl) => tbl.resourceKey.isIn(resourceKeys)))
        .go();
  }

  Future<void> clearAll() => delete(syncStateTable).go();
}
