import 'dart:io';

import '../../../../core/database/app_database.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/cache/local_api_cache_store.dart';
import '../domain/entities/order_entity.dart';
import '../domain/entities/order_item_entity.dart';
import 'datasources/order_local_datasource.dart';
import 'models/ai_draft_order_dto.dart';
import 'models/order_dto.dart';
import 'order_api_service.dart';

/// Real Order Repository - Connects to OrderApiService & implements SWR
class OrderRepository {
  final OrderApiService _apiService;
  final CacheManager _cache;
  final LocalApiCacheStore _localApiCache;
  final OrderLocalDataSource _localDataSource;

  static const String _ordersSyncResourceKey = 'orders_list';

  OrderRepository({
    required OrderApiService apiService,
    CacheManager? cacheManager,
    LocalApiCacheStore? localApiCacheStore,
    OrderLocalDataSource? localDataSource,
  }) : _apiService = apiService,
       _cache = cacheManager ?? CacheManager(),
       _localApiCache = localApiCacheStore ?? LocalApiCacheStore(),
       _localDataSource = localDataSource ?? OrderLocalDataSource();

  // Convert DTO to Entity
  OrderEntity _mapToEntity(OrderDto dto) {
    return OrderEntity(
      id: dto.id,
      orderCode: dto.orderCode,
      customerName: dto.customerName,
      customerPhone: dto.customerPhone,
      locationId: dto.locationId,
      locationName: dto.locationName,
      status: dto.status,
      items: dto.items
          .map(
            (item) => OrderItemEntity(
              id: item.id,
              productId: item.productId,
              saleItemId: item.saleItemId,
              unitName: item.unitName,
              productName: item.productName,
              price: item.price,
              quantity: item.quantity,
              discount: item.discount,
              note: item.note,
            ),
          )
          .toList(),
      subtotal: dto.subtotal,
      discountAmount: dto.discountAmount,
      taxAmount: dto.taxAmount,
      totalAmount: dto.totalAmount,
      cashAmount: dto.cashAmount,
      bankAmount: dto.bankAmount,
      debtAmount: dto.debtAmount,
      debtorId: dto.debtorId,
      note: dto.note,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      completedAt: dto.completedAt,
      cancelledAt: dto.cancelledAt,
      cancelReason: dto.cancelReason,
      invoiceNumber: dto.invoiceNumber,
      invoicedAt: dto.invoicedAt,
    );
  }

  Future<AiDraftOrderResultDto> parseDraftOrderFromAudio({
    required int locationId,
    required File audioFile,
  }) async {
    return _apiService.parseDraftOrderFromAudio(
      locationId: locationId,
      audioFile: audioFile,
    );
  }

  /// Get all orders with optional filters using SWR
  Future<void> getOrdersSWR({
    required int pageNumber,
    required int pageSize,
    String? status,
    String? locationId,
    required Function(List<OrderEntity> data, int totalCount, bool isFromCache)
    onData,
    Function(dynamic error)? onError,
  }) async {
    final key = 'orders_${locationId}_${status}_p${pageNumber}_s$pageSize';
    final scopeKey = _scopeKey(status: status, locationId: locationId);
    var hasLocalData = false;

    final localOrders = await _localDataSource.getByScopeKey(scopeKey);
    if (localOrders.isNotEmpty) {
      onData(localOrders, localOrders.length, true);
      hasLocalData = true;
    }

    final localCached = await _localApiCache.getMap(key);
    if (!hasLocalData && localCached != null) {
      final items = (localCached['items'] as List<dynamic>? ?? [])
          .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
          .map(_mapToEntity)
          .toList();
      final totalCount = localCached['total'] as int? ?? 0;
      onData(items, totalCount, true);
      hasLocalData = true;
    }

    try {
      final response = await _apiService.getOrders(
        pageNumber: pageNumber,
        pageSize: pageSize,
        status: status,
        locationId: locationId,
      );
      final dataMap = {
        'items': response.orders.map((e) => e.toJson()).toList(),
        'total': response.total,
      };
      await _localApiCache.setMap(
        key,
        dataMap,
        groupKey: 'orders',
        cacheType: 'list',
      );
      final items = response.orders.map(_mapToEntity).toList();
      await _localDataSource.replaceForScope(scopeKey, items);
      await AppDatabase().syncStateDao.upsert(
        resourceKey: _ordersSyncResourceKey,
        businessId: scopeKey,
        lastSyncedAtEpoch: DateTime.now().millisecondsSinceEpoch,
      );
      onData(items, response.total, false);
    } catch (error) {
      if (!hasLocalData && onError != null) {
        onError(error);
      }
    }
  }

  /// Get single order by ID
  Future<OrderEntity> getOrder(String orderId) async {
    final key = 'order_detail_$orderId';
    try {
      final dto = await _apiService.getOrder(orderId);
      final order = _mapToEntity(dto);
      await _localApiCache.setMap(
        key,
        dto.toJson(),
        groupKey: 'orders',
        cacheType: 'detail',
      );
      await _localDataSource.upsertDetail(order);
      return order;
    } catch (e) {
      final localOrder = await _localDataSource.getById(orderId);
      if (localOrder != null) {
        return localOrder;
      }
      final localCached = await _localApiCache.getMap(key);
      if (localCached != null) {
        return _mapToEntity(OrderDto.fromJson(localCached));
      }
      rethrow;
    }
  }

  /// Create a new order (pending)
  Future<OrderEntity> createOrder(Map<String, dynamic> requestBody) async {
    final dto = await _apiService.createOrder(requestBody);
    final order = _mapToEntity(dto);
    await _localDataSource.upsertDetail(order);
    await clearCache();
    return order;
  }

  /// Update an existing order
  Future<OrderEntity> updateOrder({
    required String orderId,
    required Map<String, dynamic> requestBody,
    String? idempotencyKey,
  }) async {
    final dto = await _apiService.updateOrder(
      orderId: orderId,
      body: requestBody,
      idempotencyKey: idempotencyKey,
    );
    final order = _mapToEntity(dto);
    await _localDataSource.upsertDetail(order);
    await clearCache();
    return order;
  }

  /// Complete an order (convert pending to completed)
  Future<OrderEntity> completeOrder(
    String orderId, {
    bool confirmLowStock = false,
  }) async {
    final dto = await _apiService.completeOrder(
      orderId,
      confirmLowStock: confirmLowStock,
    );
    final order = _mapToEntity(dto);
    await _localDataSource.upsertDetail(order);
    await clearCache();
    return order;
  }

  /// Cancel an order
  Future<bool> cancelOrder(
    String orderId, {
    required String cancelReason,
  }) async {
    final result = await _apiService.cancelOrder(
      orderId,
      cancelReason: cancelReason,
    );
    if (result) {
      await _localDataSource.deleteById(orderId);
      await clearCache();
    }
    return result;
  }

  String _scopeKey({String? status, String? locationId}) {
    return 'orders_${locationId ?? 'all'}_${status ?? 'all'}';
  }

  Future<int?> getOrdersLastSyncedAtEpoch({
    String? status,
    String? locationId,
  }) async {
    final scopeKey = _scopeKey(status: status, locationId: locationId);
    final state = await AppDatabase().syncStateDao.getState(
      resourceKey: _ordersSyncResourceKey,
      businessId: scopeKey,
    );
    return state?.lastSyncedAtEpoch;
  }

  /// Clear all cache keys related to orders
  Future<void> clearCache() async {
    await _cache.removeByPrefix('orders_');
    await _cache.removeByPrefix('home_dashboard_summary_');
    await _localApiCache.removeByGroup('orders');
  }
}
