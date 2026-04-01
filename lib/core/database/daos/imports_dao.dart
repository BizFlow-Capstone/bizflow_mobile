import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/imports_table.dart';

part 'imports_dao.g.dart';

@DriftAccessor(tables: [ImportsTable])
class ImportsDao extends DatabaseAccessor<AppDatabase> with _$ImportsDaoMixin {
  ImportsDao(super.db);

  Future<List<ImportsTableData>> getByScopeKey(String scopeKey) {
    return (select(importsTable)
          ..where((tbl) => tbl.scopeKey.equals(scopeKey))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAtEpoch)]))
        .get();
  }

  Future<ImportsTableData?> getLatestById(int id) {
    return (select(importsTable)
          ..where((tbl) => tbl.id.equals(id))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.cachedAtEpoch)]))
        .getSingleOrNull();
  }

  Future<void> replaceForScope(
    String scopeKey,
    List<ImportsTableCompanion> rows,
  ) async {
    await transaction(() async {
      final deleteQuery = delete(importsTable)
        ..where((tbl) => tbl.scopeKey.equals(scopeKey));
      await deleteQuery.go();

      if (rows.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(importsTable, rows);
        });
      }
    });
  }

  Future<void> upsert(ImportsTableCompanion row) {
    return into(importsTable).insertOnConflictUpdate(row);
  }

  Future<void> deleteById(int id) {
    return (delete(importsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> clearAll() => delete(importsTable).go();
}
