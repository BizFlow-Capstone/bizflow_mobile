import 'package:drift/drift.dart';

class EmployeesTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text()();

  TextColumn get name => text()();

  TextColumn get phone => text().withDefault(const Constant(''))();

  TextColumn get email => text().withDefault(const Constant(''))();

  TextColumn get status => text().withDefault(const Constant('active'))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get employmentStatus => text().withDefault(const Constant('accepted'))();

  IntColumn get startedAtEpoch => integer().nullable()();

  IntColumn get endedAtEpoch => integer().nullable()();

  TextColumn get assignedLocationIdsJson => text().withDefault(const Constant('[]'))();

  TextColumn get assignedLocationNamesJson => text().withDefault(const Constant('[]'))();

  IntColumn get cachedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
