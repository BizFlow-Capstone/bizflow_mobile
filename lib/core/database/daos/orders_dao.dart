import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/orders_table.dart';

part 'orders_dao.g.dart';

@DriftAccessor(tables: [OrdersTable])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  Future<List<OrdersTableData>> getByScopeKey(String scopeKey) {
    return (select(ordersTable)
          ..where((tbl) => tbl.scopeKey.equals(scopeKey))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAtEpoch)]))
        .get();
  }

  Future<OrdersTableData?> getLatestById(String id) {
    return (select(ordersTable)
          ..where((tbl) => tbl.id.equals(id))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.cachedAtEpoch)]))
        .getSingleOrNull();
  }

  Future<void> replaceForScope(
    String scopeKey,
    List<OrdersTableCompanion> rows,
  ) async {
    await transaction(() async {
      final deleteQuery = delete(ordersTable)
        ..where((tbl) => tbl.scopeKey.equals(scopeKey));
      await deleteQuery.go();

      if (rows.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(ordersTable, rows);
        });
      }
    });
  }

  Future<void> upsert(OrdersTableCompanion row) {
    return into(ordersTable).insertOnConflictUpdate(row);
  }

  Future<void> deleteById(String id) {
    return (delete(ordersTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> clearAll() => delete(ordersTable).go();
}
