import 'package:drift/drift.dart';

class InvoiceTemplateSettingsTable extends Table {
  TextColumn get accountScope => text()();

  TextColumn get payloadJson => text()();

  IntColumn get updatedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {accountScope};
}
