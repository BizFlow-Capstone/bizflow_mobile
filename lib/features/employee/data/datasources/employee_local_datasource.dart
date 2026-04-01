import '../../../../core/database/app_database.dart';
import '../../domain/entities/employee_entity.dart';
import '../mappers/employee_local_mapper.dart';

class EmployeeLocalDataSource {
  EmployeeLocalDataSource({AppDatabase? database}) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<List<EmployeeEntity>> getByBusinessId(String businessId) async {
    final rows = await _database.employeesDao.getByBusinessId(businessId);
    return rows.map(EmployeeLocalMapper.toEntity).toList();
  }

  Future<void> replaceForBusiness(
    String businessId,
    List<EmployeeEntity> employees,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = employees
        .map(
          (entity) => EmployeeLocalMapper.toCompanion(
            entity,
            businessId: businessId,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.employeesDao.replaceForBusiness(businessId, rows);
  }

  Future<void> clearAll() => _database.employeesDao.clearAll();
}
