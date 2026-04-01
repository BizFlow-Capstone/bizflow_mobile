import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/invoice_template_settings_table.dart';

part 'invoice_template_settings_dao.g.dart';

@DriftAccessor(tables: [InvoiceTemplateSettingsTable])
class InvoiceTemplateSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$InvoiceTemplateSettingsDaoMixin {
  InvoiceTemplateSettingsDao(super.db);

  Future<InvoiceTemplateSettingsTableData?> getByAccountScope(String accountScope) {
    return (select(invoiceTemplateSettingsTable)
          ..where((tbl) => tbl.accountScope.equals(accountScope))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsert({
    required String accountScope,
    required String payloadJson,
    required int updatedAtEpoch,
  }) {
    return into(invoiceTemplateSettingsTable).insertOnConflictUpdate(
      InvoiceTemplateSettingsTableCompanion.insert(
        accountScope: accountScope,
        payloadJson: payloadJson,
        updatedAtEpoch: updatedAtEpoch,
      ),
    );
  }

  Future<void> removeByAccountScope(String accountScope) {
    return (delete(invoiceTemplateSettingsTable)
          ..where((tbl) => tbl.accountScope.equals(accountScope)))
        .go();
  }
}
