import 'package:drift/drift.dart';

class ProductsTable extends Table {
  TextColumn get id => text()();

  TextColumn get scopeKey => text()();

  TextColumn get name => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  RealColumn get price => real().withDefault(const Constant(0.0))();

  IntColumn get quantity => integer().withDefault(const Constant(0))();

  TextColumn get imageUrl => text().nullable()();

  TextColumn get barcode => text().nullable()();

  TextColumn get category => text().nullable()();

  RealColumn get costPrice => real().nullable()();

  RealColumn get salePrice => real().nullable()();

  TextColumn get unit => text().nullable()();

  BoolColumn get trackInventory =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get createdAtEpoch => integer().nullable()();

  IntColumn get locationId => integer().nullable()();

  TextColumn get businessTypeId => text().nullable()();

  TextColumn get manufacturer => text().nullable()();

  TextColumn get businessLocationName => text().nullable()();

  TextColumn get saleItemsJson => text().withDefault(const Constant('[]'))();

  IntColumn get cachedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
