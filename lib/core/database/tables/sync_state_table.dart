import 'package:drift/drift.dart';

class SyncStateTable extends Table {
  TextColumn get resourceKey => text()();

  TextColumn get businessId => text().withDefault(const Constant('global'))();

  IntColumn get lastSyncedAtEpoch => integer()();

  TextColumn get etag => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {resourceKey, businessId};
}
