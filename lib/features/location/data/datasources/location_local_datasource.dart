import '../../../../core/database/app_database.dart';
import '../mappers/location_local_mapper.dart';
import '../../domain/entities/location_entity.dart';

class LocationLocalDataSource {
  LocationLocalDataSource({AppDatabase? database}) : _databaseOverride = database;

  final AppDatabase? _databaseOverride;

  AppDatabase get _database => _databaseOverride ?? AppDatabase();

  Future<List<LocationEntity>> getByBusinessId(String? businessId) async {
    final rows = await _database.locationsDao.getByBusinessId(businessId);
    return rows.map(LocationLocalMapper.toEntity).toList();
  }

  Stream<List<LocationEntity>> watchByBusinessId(String? businessId) {
    return _database.locationsDao
        .watchByBusinessId(businessId)
      .map((rows) => rows.map(LocationLocalMapper.toEntity).toList());
  }

  Future<void> replaceForBusiness(
    String? businessId,
    List<LocationEntity> locations,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = locations
        .map(
          (e) => LocationLocalMapper.toCompanion(
            e,
            businessId: businessId,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.locationsDao.replaceForBusiness(businessId, rows);
  }

  Future<void> upsertAll(String? businessId, List<LocationEntity> locations) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = locations
        .map(
          (e) => LocationLocalMapper.toCompanion(
            e,
            businessId: businessId,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.locationsDao.upsertAll(rows);
  }

  Future<void> clearAll() => _database.locationsDao.clearAll();
}
