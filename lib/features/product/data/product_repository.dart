import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/product_entity.dart';
import 'datasources/product_local_datasource.dart';
import 'product_api_service.dart';
import 'models/business_type_model.dart';
import 'models/product_dto.dart';
import '../../../shared/cache/local_api_cache_store.dart';
import '../../../shared/context/business_context.dart';

/// Product Repository - Orchestrates product data flow
///
/// Architecture: BLoC → Repository → Service → ApiClient
class ProductRepository {
  final ProductApiService _service;
  final ProductLocalDataSource _localDataSource;
  final LocalApiCacheStore _localApiCache;

  static const String _productsSyncResourceKey = 'products_list';
  static const String _productDirtyResourcePrefix = 'dirty_product:';

  ProductRepository({
    required ProductApiService service,
    ProductLocalDataSource? localDataSource,
    LocalApiCacheStore? localApiCacheStore,
  }) : _service = service,
       _localDataSource = localDataSource ?? ProductLocalDataSource(),
       _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  Future<List<ProductEntity>> getCachedProducts(String scopeKey) {
    return _localDataSource.getByScopeKey(scopeKey);
  }

  Future<ProductEntity?> getCachedProductDetail(String productId) {
    return _localDataSource.getById(productId);
  }

  Future<void> saveCachedProducts(
    String scopeKey,
    List<ProductEntity> products,
  ) async {
    final mergedProducts = await _mergeWithDirtyProducts(scopeKey, products);
    await _localDataSource.replaceForScope(scopeKey, mergedProducts);
    await AppDatabase().syncStateDao.upsert(
      resourceKey: _productsSyncResourceKey,
      businessId: scopeKey,
      lastSyncedAtEpoch: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> markProductsDirty(
    String scopeKey,
    List<String> productIds,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = productIds
        .toSet()
        .map(
          (id) => SyncStateTableCompanion.insert(
            resourceKey: '$_productDirtyResourcePrefix$id',
            businessId: Value(scopeKey),
            lastSyncedAtEpoch: now,
            etag: const Value('dirty'),
          ),
        )
        .toList();
    await AppDatabase().syncStateDao.upsertAll(rows);
  }

  Future<void> clearProductsDirty(String scopeKey, List<String> productIds) {
    final resourceKeys = productIds
        .toSet()
        .map((id) => '$_productDirtyResourcePrefix$id')
        .toList();
    return AppDatabase().syncStateDao.deleteByBusinessAndResourceKeys(
      businessId: scopeKey,
      resourceKeys: resourceKeys,
    );
  }

  Future<int?> getProductsLastSyncedAtEpoch(String scopeKey) async {
    final state = await AppDatabase().syncStateDao.getState(
      resourceKey: _productsSyncResourceKey,
      businessId: scopeKey,
    );
    return state?.lastSyncedAtEpoch;
  }

  Future<void> clearCachedProducts() {
    return _localDataSource.clearAll();
  }

  Future<List<ProductEntity>> _mergeWithDirtyProducts(
    String scopeKey,
    List<ProductEntity> incoming,
  ) async {
    final dirtyRows = await AppDatabase().syncStateDao
        .listByBusinessAndResourcePrefix(
          businessId: scopeKey,
          resourcePrefix: _productDirtyResourcePrefix,
        );
    if (dirtyRows.isEmpty) return incoming;

    final dirtyIds = dirtyRows
        .map(
          (row) =>
              row.resourceKey.replaceFirst(_productDirtyResourcePrefix, ''),
        )
        .where((id) => id.isNotEmpty)
        .toSet();
    if (dirtyIds.isEmpty) return incoming;

    final localProducts = await _localDataSource.getByScopeKey(scopeKey);
    final localById = {for (final item in localProducts) item.id: item};

    final merged = incoming
        .where((item) => !dirtyIds.contains(item.id))
        .toList(growable: true);
    for (final dirtyId in dirtyIds) {
      final local = localById[dirtyId];
      if (local != null) {
        merged.add(local);
      }
    }
    return merged;
  }

  /// Get products for a specific location (Legacy endpoint)
  Future<List<ProductEntity>> getLocationProducts(String locationId) async {
    try {
      final dtos = await _service.getLocationProducts(locationId);
      return dtos
          .map(
            (dto) => ProductEntity(
              id: dto.id,
              name: dto.name,
              description: dto.description,
              price: dto.price,
              costPrice: dto.costPrice,
              salePrice: dto.salePrice,
              quantity: dto.quantity,
              imageUrl: dto.imageUrl,
              businessTypeId: dto.businessTypeId,
              manufacturer: dto.manufacturer,
              businessLocationName: dto.businessLocationName,
              unit: dto.unit,
              barcode: dto.barcode,
              isActive: dto.isActive,
              trackInventory: dto.trackInventory,
              saleItems: dto.saleItems,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('ProductRepository.getLocationProducts error: $e');
      rethrow;
    }
  }

  /// Get all products with filters and pagination
  Future<dynamic> getProducts({
    int? locationId,
    String? search,
    String? businessTypeId,
    double? minCostPrice,
    double? maxCostPrice,
    int? minStock,
    int? maxStock,
    String? status,
    bool? trackInventory,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await _service.getProducts(
        locationId: locationId,
        search: search,
        businessTypeId: businessTypeId,
        minCostPrice: minCostPrice,
        maxCostPrice: maxCostPrice,
        minStock: minStock,
        maxStock: maxStock,
        status: status,
        trackInventory: trackInventory,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('ProductRepository.getProducts error: $e');
      rethrow;
    }
  }

  /// Get product detail with images and sale items
  Future<ProductEntity?> getProductDetail(String productId) async {
    final detailCacheKey = 'product_detail_$productId';
    try {
      final response = await _service.getProductDetail(productId);
      if (response != null &&
          response is Map<String, dynamic> &&
          response['success'] == true &&
          response['data'] != null) {
        final payload = Map<String, dynamic>.from(
          response['data'] as Map<String, dynamic>,
        );
        final product = _mapDtoToEntity(ProductDto.fromJson(payload));
        await _localApiCache.setMap(
          detailCacheKey,
          payload,
          groupKey: 'products',
          cacheType: 'detail',
        );
        await _localDataSource.upsertDetail(product);
        return product;
      }
      return await _localDataSource.getById(productId);
    } catch (e) {
      final localCached = await _localApiCache.getMap(detailCacheKey);
      if (localCached != null) {
        final cachedEntity = _mapDtoToEntity(ProductDto.fromJson(localCached));
        final localProduct = await _localDataSource.getById(productId);
        if (localProduct != null) {
          return _mergePreferDetailed(localProduct, cachedEntity);
        }
        return cachedEntity;
      }

      final localProduct = await _localDataSource.getById(productId);
      if (localProduct != null) {
        return localProduct;
      }

      debugPrint('ProductRepository.getProductDetail error: $e');
      rethrow;
    }
  }

  ProductEntity _mergePreferDetailed(
    ProductEntity local,
    ProductEntity cachedDetail,
  ) {
    return local.copyWith(
      name: cachedDetail.name.isNotEmpty ? cachedDetail.name : local.name,
      description: cachedDetail.description ?? local.description,
      imageUrl: cachedDetail.imageUrl ?? local.imageUrl,
      barcode: cachedDetail.barcode ?? local.barcode,
      category: cachedDetail.category ?? local.category,
      costPrice: cachedDetail.costPrice ?? local.costPrice,
      salePrice: cachedDetail.salePrice ?? local.salePrice,
      unit: cachedDetail.unit ?? local.unit,
      manufacturer: cachedDetail.manufacturer ?? local.manufacturer,
      businessLocationName:
          cachedDetail.businessLocationName ?? local.businessLocationName,
      businessTypeId: cachedDetail.businessTypeId ?? local.businessTypeId,
      createdAt: cachedDetail.createdAt ?? local.createdAt,
      locationId: cachedDetail.locationId ?? local.locationId,
        trackInventory: cachedDetail.trackInventory,
      saleItems: cachedDetail.saleItems.isNotEmpty
          ? cachedDetail.saleItems
          : local.saleItems,
      price: cachedDetail.price,
      quantity: cachedDetail.quantity,
      isActive: cachedDetail.isActive,
    );
  }

  /// Get product sale items (price tiers/unit conversions)
  Future<dynamic> getProductSaleItems(String productId) async {
    final businessId = BusinessContext().currentBusinessId ?? 'all';
    final cacheKey = 'cache_sale_items_${businessId}_$productId';

    final cached = await _localApiCache.getMap(cacheKey);
    if (cached != null) {
      unawaited(
        _refreshSaleItemsCache(cacheKey: cacheKey, productId: productId),
      );
      return {'data': cached['data'] ?? <dynamic>[]};
    }

    try {
      return await _fetchSaleItemsAndCache(
        cacheKey: cacheKey,
        productId: productId,
      );
    } catch (e) {
      debugPrint('ProductRepository.getProductSaleItems error: $e');
      rethrow;
    }
  }

  Future<void> _refreshSaleItemsCache({
    required String cacheKey,
    required String productId,
  }) async {
    try {
      await _fetchSaleItemsAndCache(cacheKey: cacheKey, productId: productId);
    } catch (_) {
      // Best effort background refresh.
    }
  }

  Future<Map<String, dynamic>> _fetchSaleItemsAndCache({
    required String cacheKey,
    required String productId,
  }) async {
    final response = await _service.getProductSaleItems(productId);
    final normalized = _normalizeSaleItems(response);
    await _localApiCache.setMap(
      cacheKey,
      {'data': normalized},
      groupKey: 'product_sale_items',
      cacheType: 'list',
    );
    return {'data': normalized};
  }

  List<Map<String, dynamic>> _normalizeSaleItems(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic> && data['saleItems'] is List) {
        return (data['saleItems'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    return <Map<String, dynamic>>[];
  }

  /// Get product cost price history
  Future<dynamic> getProductCostPriceHistory(String productId) async {
    try {
      return await _service.getProductCostPriceHistory(productId);
    } catch (e) {
      debugPrint('ProductRepository.getProductCostPriceHistory error: $e');
      rethrow;
    }
  }

  /// Bulk adjust selected sale-item selling prices
  Future<dynamic> bulkAdjustSellingPrice({
    required List<int> saleItemIds,
    required double deltaAmount,
  }) async {
    try {
      final result = await _service.bulkAdjustSellingPrice(
        saleItemIds: saleItemIds,
        deltaAmount: deltaAmount,
      );
      await clearCache();
      return result;
    } catch (e) {
      debugPrint('ProductRepository.bulkAdjustSellingPrice error: $e');
      rethrow;
    }
  }

  /// Adjust product stock manually
  Future<dynamic> adjustProductStock({
    required String productId,
    required int stock,
    String? memo,
    double? costPrice,
  }) async {
    try {
      final result = await _service.adjustProductStock(
        productId: productId,
        stock: stock,
        memo: memo,
        costPrice: costPrice,
      );
      await clearCache();
      return result;
    } catch (e) {
      debugPrint('ProductRepository.adjustProductStock error: $e');
      rethrow;
    }
  }

  /// Create new product
  Future<dynamic> createProduct({
    required String productName,
    required String unit,
    required String businessTypeId, // Required per spec
    required int locationId,
    String? sku,
    bool trackInventory = true,
    double? costPrice,
    double? price,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
  }) async {
    try {
      final result = await _service.createProduct(
        productName: productName,
        unit: unit,
        businessTypeId: businessTypeId,
        locationId: locationId,
        sku: sku,
        trackInventory: trackInventory,
        costPrice: costPrice,
        price: price,
        stock: stock,
        manufacturer: manufacturer,
        priceTiers: priceTiers,
        imagePath: imagePath,
      );
      await clearCache();
      return result;
    } catch (e) {
      debugPrint('ProductRepository.createProduct error: $e');
      rethrow;
    }
  }

  /// Update existing product
  Future<dynamic> updateProduct(
    String productId, {
    required String productName, // Required per spec
    required String unit, // Required per spec
    required int locationId, // Required per spec
    required String businessTypeId, // Required per spec
    String? sku,
    bool? trackInventory,
    double? costPrice,
    double? price,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      final result = await _service.updateProduct(
        productId,
        productName: productName,
        unit: unit,
        locationId: locationId,
        businessTypeId: businessTypeId,
        sku: sku,
        trackInventory: trackInventory,
        costPrice: costPrice,
        price: price,
        stock: stock,
        manufacturer: manufacturer,
        priceTiers: priceTiers,
        imagePath: imagePath,
        removeImage: removeImage,
      );
      await clearCache();
      return result;
    } catch (e) {
      debugPrint('ProductRepository.updateProduct error: $e');
      rethrow;
    }
  }

  /// Update product status (toggle active/inactive)
  Future<dynamic> updateProductStatus(
    String productId, {
    required bool status,
  }) async {
    try {
      final result = await _service.updateProductStatus(
        productId,
        status: status,
      );
      await clearCache();
      return result;
    } catch (e) {
      debugPrint('ProductRepository.updateProductStatus error: $e');
      rethrow;
    }
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _service.deleteProduct(productId);
      await clearCache();
    } catch (e) {
      debugPrint('ProductRepository.deleteProduct error: $e');
      rethrow;
    }
  }

  /// Get business types
  Future<List<BusinessTypeDto>> getBusinessTypes() async {
    const cacheKey = 'product_business_types';

    final cachedBusinessTypes = await _readBusinessTypesFromCache(cacheKey);
    if (cachedBusinessTypes.isNotEmpty) {
      unawaited(_refreshBusinessTypesCache(cacheKey));
      return cachedBusinessTypes;
    }

    try {
      final result = await _service.getBusinessTypes();
      final normalized = result.map((item) => item.toJson()).toList();

      await _localApiCache.setMap(
        cacheKey,
        {'data': normalized},
        groupKey: 'product_business_types',
        cacheType: 'list',
      );

      return result;
    } catch (e) {
      final fallback = await _readBusinessTypesFromCache(cacheKey);
      if (fallback.isNotEmpty) {
        return fallback;
      }
      debugPrint('ProductRepository.getBusinessTypes error: $e');
      rethrow;
    }
  }

  Future<void> _refreshBusinessTypesCache(String cacheKey) async {
    try {
      final result = await _service.getBusinessTypes();
      final normalized = result.map((item) => item.toJson()).toList();
      await _localApiCache.setMap(
        cacheKey,
        {'data': normalized},
        groupKey: 'product_business_types',
        cacheType: 'list',
      );
    } catch (_) {
      // Best effort background refresh.
    }
  }

  Future<List<BusinessTypeDto>> _readBusinessTypesFromCache(
    String cacheKey,
  ) async {
    final cached = await _localApiCache.getMap(cacheKey);
    if (cached == null) {
      return <BusinessTypeDto>[];
    }

    final data = cached['data'];
    if (data is! List) {
      return <BusinessTypeDto>[];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => BusinessTypeDto.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  ProductEntity _mapDtoToEntity(ProductDto dto) {
    return ProductEntity(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      price: dto.price,
      costPrice: dto.costPrice,
      salePrice: dto.salePrice,
      quantity: dto.quantity,
      imageUrl: dto.imageUrl,
      businessTypeId: dto.businessTypeId,
      manufacturer: dto.manufacturer,
      businessLocationName: dto.businessLocationName,
      unit: dto.unit,
      barcode: dto.barcode,
      isActive: dto.isActive,
      trackInventory: dto.trackInventory,
      saleItems: dto.saleItems,
    );
  }

  Future<void> clearCache() async {
    await _localApiCache.removeByGroup('products');
    await _localApiCache.removeByGroup('product_sale_items');
    await _localApiCache.removeByGroup('product_business_types');
    await clearCachedProducts();
  }
}
