import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [ProductsTable])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<ProductsTableData>> getByScopeKey(String scopeKey) {
    return (select(
      productsTable,
    )..where((tbl) => tbl.scopeKey.equals(scopeKey))).get();
  }

  Future<ProductsTableData?> getById(String id) {
    return (select(
      productsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Stream<List<ProductsTableData>> watchByScopeKey(String scopeKey) {
    return (select(
      productsTable,
    )..where((tbl) => tbl.scopeKey.equals(scopeKey))).watch();
  }

  Future<void> replaceForScope(
    String scopeKey,
    List<ProductsTableCompanion> rows,
  ) async {
    await transaction(() async {
      final deleteQuery = delete(productsTable)
        ..where((tbl) => tbl.scopeKey.equals(scopeKey));
      await deleteQuery.go();

      if (rows.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(productsTable, rows);
        });
      }
    });
  }

  Future<void> upsertAll(List<ProductsTableCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(productsTable, rows);
    });
  }

  Future<void> upsert(ProductsTableCompanion row) {
    return into(productsTable).insertOnConflictUpdate(row);
  }

  Future<void> clearAll() => delete(productsTable).go();
}
