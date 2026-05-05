import 'package:drift/drift.dart';

class LocationsTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text().nullable()();

  TextColumn get name => text()();

  TextColumn get address => text().withDefault(const Constant(''))();

  TextColumn get district => text().withDefault(const Constant(''))();

  TextColumn get city => text().withDefault(const Constant(''))();

  TextColumn get phone => text().withDefault(const Constant(''))();

  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  TextColumn get ownerName => text().withDefault(const Constant(''))();

  TextColumn get ownerProfileId => text().nullable()();

  TextColumn get taxCode => text().nullable()();

  TextColumn get employeeIdsJson => text().withDefault(const Constant('[]'))();

  BoolColumn get isOwner => boolean().withDefault(const Constant(false))();

  IntColumn get updatedAtEpoch => integer().nullable()();

  IntColumn get cachedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
