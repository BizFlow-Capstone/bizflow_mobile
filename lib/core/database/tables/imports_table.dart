import 'package:drift/drift.dart';

class ImportsTable extends Table {
  IntColumn get id => integer()();

  TextColumn get scopeKey => text()();

  TextColumn get importCode => text().withDefault(const Constant(''))();

  TextColumn get importType => text().withDefault(const Constant(''))();

  TextColumn get status => text().withDefault(const Constant(''))();

  IntColumn get businessLocationId => integer()();

  TextColumn get businessLocationName =>
      text().withDefault(const Constant(''))();

  TextColumn get supplier => text().nullable()();

  TextColumn get note => text().nullable()();

  IntColumn get receivedAtEpoch => integer().nullable()();

  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();

  IntColumn get createdAtEpoch => integer()();

  IntColumn get updatedAtEpoch => integer().nullable()();

  TextColumn get imageUrl => text().nullable()();

  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();

  IntColumn get cachedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id, scopeKey};
}
