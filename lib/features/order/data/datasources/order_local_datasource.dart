import '../../../../core/database/app_database.dart';
import '../../domain/entities/order_entity.dart';
import '../mappers/order_local_mapper.dart';

class OrderLocalDataSource {
  OrderLocalDataSource({AppDatabase? database})
    : _databaseOverride = database;

  final AppDatabase? _databaseOverride;

  AppDatabase get _database => _databaseOverride ?? AppDatabase();

  Future<List<OrderEntity>> getByScopeKey(String scopeKey) async {
    final rows = await _database.ordersDao.getByScopeKey(scopeKey);
    return rows.map(OrderLocalMapper.toEntity).toList();
  }

  Future<OrderEntity?> getById(String orderId) async {
    final row = await _database.ordersDao.getLatestById(orderId);
    return row == null ? null : OrderLocalMapper.toEntity(row);
  }

  Future<void> replaceForScope(
    String scopeKey,
    List<OrderEntity> orders,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = orders
        .map(
          (entity) => OrderLocalMapper.toCompanion(
            entity,
            scopeKey: scopeKey,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.ordersDao.replaceForScope(scopeKey, rows);
  }

  Future<void> upsertDetail(OrderEntity order) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.ordersDao.upsert(
      OrderLocalMapper.toCompanion(
        order,
        scopeKey: 'detail',
        cachedAtEpoch: now,
      ),
    );
  }

  Future<void> deleteById(String orderId) =>
      _database.ordersDao.deleteById(orderId);

  Future<void> clearAll() => _database.ordersDao.clearAll();
}
