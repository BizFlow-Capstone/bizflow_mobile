import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/employees_table.dart';

part 'employees_dao.g.dart';

@DriftAccessor(tables: [EmployeesTable])
class EmployeesDao extends DatabaseAccessor<AppDatabase> with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  Future<List<EmployeesTableData>> getByBusinessId(String businessId) {
    return (select(employeesTable)..where((tbl) => tbl.businessId.equals(businessId))).get();
  }

  Future<void> replaceForBusiness(
    String businessId,
    List<EmployeesTableCompanion> rows,
  ) async {
    await transaction(() async {
      final deleteQuery = delete(employeesTable)..where((tbl) => tbl.businessId.equals(businessId));
      await deleteQuery.go();

      if (rows.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(employeesTable, rows);
        });
      }
    });
  }

  Future<void> clearAll() => delete(employeesTable).go();
}
