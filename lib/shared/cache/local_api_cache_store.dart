import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class LocalApiCacheStore {
  LocalApiCacheStore({AppDatabase? database}) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<Map<String, dynamic>?> getMap(String cacheKey) async {
    final row = await _database.apiCacheDao.getByKey(cacheKey);
    if (row == null) return null;
    try {
      final parsed = jsonDecode(row.payloadJson);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setMap(
    String cacheKey,
    Map<String, dynamic> payload, {
    String? groupKey,
    String cacheType = 'list',
  }) {
    return _database.apiCacheDao.upsert(
      ApiCacheEntriesTableCompanion.insert(
        cacheKey: cacheKey,
        payloadJson: jsonEncode(payload),
        cachedAtEpoch: DateTime.now().millisecondsSinceEpoch,
        groupKey: Value(groupKey),
        cacheType: Value(cacheType),
      ),
    );
  }

  Future<void> removeByKey(String cacheKey) {
    return _database.apiCacheDao.removeByKey(cacheKey);
  }

  Future<void> removeByGroup(String groupKey) {
    return _database.apiCacheDao.removeByGroup(groupKey);
  }
}
