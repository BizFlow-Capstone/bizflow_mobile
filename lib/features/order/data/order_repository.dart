import '../../../../shared/cache/cache_manager.dart';
import '../domain/entities/order_entity.dart';
import '../domain/entities/order_item_entity.dart';
import 'order_api_service.dart';
import 'models/order_dto.dart';

/// Real Order Repository - Connects to OrderApiService & implements SWR
class OrderRepository {
  final OrderApiService _apiService;
  final CacheManager _cache;

  OrderRepository({
    required OrderApiService apiService,
    CacheManager? cacheManager,
  })  : _apiService = apiService,
        _cache = cacheManager ?? CacheManager();

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

  /// Get all orders with optional filters using SWR
  Future<void> getOrdersSWR({
    required int pageNumber,
    required int pageSize,
    String? status,
    String? locationId,
    required Function(
      List<OrderEntity> data,
      int totalCount,
      bool isFromCache,
    )
    onData,
    Function(dynamic error)? onError,
  }) async {
    final key = 'orders_${locationId}_${status}_p${pageNumber}_s$pageSize';

    await _cache.fetchWithSWR<Map<String, dynamic>>(
      key: key,
      fetcher:
          () => _apiService
              .getOrders(
                pageNumber: pageNumber,
                pageSize: pageSize,
                status: status,
                locationId: locationId,
              )
              .then((res) => {
                'items': res.orders.map((e) => e.toJson()).toList(),
                'total': res.total,
              }),
      onData: (dataMap, isFromCache) {
        final items =
            (dataMap['items'] as List<dynamic>? ?? [])
                .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
                .map(_mapToEntity)
                .toList();
        final totalCount = dataMap['total'] as int? ?? 0;
        onData(items, totalCount, isFromCache);
      },
      onError: onError,
      toJson: (data) => data,
      fromJson: (json) => json,
    );
  }

  /// Get single order by ID
  Future<OrderEntity> getOrder(String orderId) async {
    final dto = await _apiService.getOrder(orderId);
    return _mapToEntity(dto);
  }

  /// Create a new order (pending)
  Future<OrderEntity> createOrder(Map<String, dynamic> requestBody) async {
    final dto = await _apiService.createOrder(requestBody);
    return _mapToEntity(dto);
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
    return _mapToEntity(dto);
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
    return _mapToEntity(dto);
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId, {required String cancelReason}) async {
    return await _apiService.cancelOrder(orderId, cancelReason: cancelReason);
  }

  /// Clear all cache keys related to orders
  Future<void> clearCache() async {
    await _cache.removeByPrefix('orders_');
  }
}
