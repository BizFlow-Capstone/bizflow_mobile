import 'package:drift/drift.dart';

class ApiCacheEntriesTable extends Table {
  TextColumn get cacheKey => text()();

  TextColumn get groupKey => text().nullable()();

  TextColumn get payloadJson => text()();

  TextColumn get cacheType => text().withDefault(const Constant('list'))();

  IntColumn get cachedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}
