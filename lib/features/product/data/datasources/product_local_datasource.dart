import '../../../../core/database/app_database.dart';
import '../../domain/entities/product_entity.dart';
import '../mappers/product_local_mapper.dart';

class ProductLocalDataSource {
  ProductLocalDataSource({AppDatabase? database})
    : _databaseOverride = database;

  final AppDatabase? _databaseOverride;

  AppDatabase get _database => _databaseOverride ?? AppDatabase();

  Future<List<ProductEntity>> getByScopeKey(String scopeKey) async {
    final rows = await _database.productsDao.getByScopeKey(scopeKey);
    return rows.map(ProductLocalMapper.toEntity).toList();
  }

  Future<ProductEntity?> getById(String productId) async {
    final row = await _database.productsDao.getById(productId);
    return row == null ? null : ProductLocalMapper.toEntity(row);
  }

  Future<void> replaceForScope(
    String scopeKey,
    List<ProductEntity> products,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = products
        .map(
          (entity) => ProductLocalMapper.toCompanion(
            entity,
            scopeKey: scopeKey,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.productsDao.replaceForScope(scopeKey, rows);
  }

  Future<void> upsertAll(String scopeKey, List<ProductEntity> products) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = products
        .map(
          (entity) => ProductLocalMapper.toCompanion(
            entity,
            scopeKey: scopeKey,
            cachedAtEpoch: now,
          ),
        )
        .toList();
    await _database.productsDao.upsertAll(rows);
  }

  Future<void> upsertDetail(ProductEntity product) async {
    final existing = await _database.productsDao.getById(product.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.productsDao.upsert(
      ProductLocalMapper.toCompanion(
        product,
        scopeKey: existing?.scopeKey ?? 'detail_${product.id}',
        cachedAtEpoch: now,
      ),
    );
  }

  Future<void> clearAll() => _database.productsDao.clearAll();
}
