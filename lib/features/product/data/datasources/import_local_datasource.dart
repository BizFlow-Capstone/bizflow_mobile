import '../../../../core/database/app_database.dart';
import '../mappers/import_local_mapper.dart';
import '../models/import_model.dart';

class ImportLocalDataSource {
  ImportLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<List<ImportHistoryItemModel>> getByScopeKey(String scopeKey) async {
    final rows = await _database.importsDao.getByScopeKey(scopeKey);
    return rows.map(ImportLocalMapper.toHistoryItem).toList();
  }

  Future<ImportDetailModel?> getById(int importId) async {
    final row = await _database.importsDao.getLatestById(importId);
    return row == null ? null : ImportLocalMapper.toDetailModel(row);
  }

  Future<void> replaceForScope(
    String scopeKey,
    List<ImportHistoryItemModel> imports,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = imports
        .map(
          (model) => ImportLocalMapper.toCompanion(
            model,
            scopeKey: scopeKey,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.importsDao.replaceForScope(scopeKey, rows);
  }

  Future<void> upsertDetail(ImportDetailModel detail) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.importsDao.upsert(
      ImportLocalMapper.toCompanion(
        detail,
        scopeKey: 'detail',
        cachedAtEpoch: now,
        items: detail.items,
      ),
    );
  }

  Future<void> deleteById(int importId) =>
      _database.importsDao.deleteById(importId);

  Future<void> clearAll() => _database.importsDao.clearAll();
}
