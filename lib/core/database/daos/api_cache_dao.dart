import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/api_cache_entries_table.dart';

part 'api_cache_dao.g.dart';

@DriftAccessor(tables: [ApiCacheEntriesTable])
class ApiCacheDao extends DatabaseAccessor<AppDatabase> with _$ApiCacheDaoMixin {
  ApiCacheDao(super.db);

  Future<ApiCacheEntriesTableData?> getByKey(String cacheKey) {
    return (select(apiCacheEntriesTable)
          ..where((tbl) => tbl.cacheKey.equals(cacheKey))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<ApiCacheEntriesTableData>> getByGroup(String groupKey) {
    return (select(apiCacheEntriesTable)..where((tbl) => tbl.groupKey.equals(groupKey))).get();
  }

  Future<void> upsert(ApiCacheEntriesTableCompanion entry) async {
    await into(apiCacheEntriesTable).insertOnConflictUpdate(entry);
  }

  Future<void> removeByKey(String cacheKey) {
    return (delete(apiCacheEntriesTable)..where((tbl) => tbl.cacheKey.equals(cacheKey))).go();
  }

  Future<void> removeByGroup(String groupKey) {
    return (delete(apiCacheEntriesTable)..where((tbl) => tbl.groupKey.equals(groupKey))).go();
  }

  Future<void> clearAll() => delete(apiCacheEntriesTable).go();
}
