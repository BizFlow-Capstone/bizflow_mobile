import 'package:flutter/foundation.dart';
import '../domain/entities/order_entity.dart';
import '../domain/entities/order_item_entity.dart';
import 'models/order_dto.dart';
import 'models/order_item_dto.dart';
import 'order_api_service.dart';

/// Order Repository - Orchestrates data sources and business logic
///
/// Responsibilities:
/// 1. Coordinate between API service and domain logic
/// 2. Transform DTOs to Entities
/// 3. Cache data in memory
/// 4. Handle data transformations and business rules
class OrderRepository {
  final OrderApiService _apiService;

  OrderRepository({required OrderApiService apiService})
    : _apiService = apiService;

  // Cache
  List<OrderEntity> _ordersCache = [];
  Map<String, OrderEntity> _orderDetailsCache = {};

  /// Get all orders with optional filters
  Future<List<OrderEntity>> getOrders({
    int pageNumber = 1,
    int pageSize = 20,
    String? status,
    String? locationId,
  }) async {
    try {
      final responseDto = await _apiService.getOrders(
        pageNumber: pageNumber,
        pageSize: pageSize,
        status: status,
        locationId: locationId,
      );

      _ordersCache = responseDto.orders
          .map((dto) => _dtoToEntity(dto))
          .toList();

      return _ordersCache;
    } catch (e) {
      debugPrint('OrderRepository.getOrders error: $e');
      rethrow;
    }
  }

  /// Get draft orders
  Future<List<OrderEntity>> getDraftOrders({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final responseDto = await _apiService.getDraftOrders(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

      return responseDto.orders.map((dto) => _dtoToEntity(dto)).toList();
    } catch (e) {
      debugPrint('OrderRepository.getDraftOrders error: $e');
      rethrow;
    }
  }

  /// Get single order by ID
  Future<OrderEntity> getOrder(String orderId) async {
    try {
      // Check cache first
      if (_orderDetailsCache.containsKey(orderId)) {
        return _orderDetailsCache[orderId]!;
      }

      final dto = await _apiService.getOrder(orderId);
      final entity = _dtoToEntity(dto);
      _orderDetailsCache[orderId] = entity;

      return entity;
    } catch (e) {
      debugPrint('OrderRepository.getOrder error: $e');
      rethrow;
    }
  }

  /// Create a new order
  Future<OrderEntity> createOrder({
    required String locationId,
    required List<OrderItemEntity> items,
    String? note,
  }) async {
    try {
      final itemsJson = items
          .map(
            (item) => <String, dynamic>{
              'productId': item.productId,
              'productName': item.productName,
              'price': item.price,
              'quantity': item.quantity,
              'discount': item.discount,
              'note': item.note,
            },
          )
          .toList();

      final dto = await _apiService.createOrder(
        locationId: locationId,
        items: itemsJson,
        note: note,
      );

      final entity = _dtoToEntity(dto);
      _ordersCache.add(entity);

      return entity;
    } catch (e) {
      debugPrint('OrderRepository.createOrder error: $e');
      rethrow;
    }
  }

  /// Update an existing order
  Future<OrderEntity> updateOrder({
    required String orderId,
    String? note,
    List<OrderItemEntity>? items,
  }) async {
    try {
      final itemsJson = items
          ?.map(
            (item) => <String, dynamic>{
              'productId': item.productId,
              'productName': item.productName,
              'price': item.price,
              'quantity': item.quantity,
              'discount': item.discount,
              'note': item.note,
            },
          )
          .toList();

      final dto = await _apiService.updateOrder(
        orderId: orderId,
        note: note,
        items: itemsJson,
      );

      final entity = _dtoToEntity(dto);

      // Update cache
      final index = _ordersCache.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _ordersCache[index] = entity;
      }
      _orderDetailsCache[orderId] = entity;

      return entity;
    } catch (e) {
      debugPrint('OrderRepository.updateOrder error: $e');
      rethrow;
    }
  }

  /// Publish an order (convert draft to invoice)
  Future<OrderEntity> publishOrder(String orderId) async {
    try {
      final dto = await _apiService.publishOrder(orderId);
      final entity = _dtoToEntity(dto);

      // Update cache
      final index = _ordersCache.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _ordersCache[index] = entity;
      }
      _orderDetailsCache[orderId] = entity;

      return entity;
    } catch (e) {
      debugPrint('OrderRepository.publishOrder error: $e');
      rethrow;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    try {
      final success = await _apiService.cancelOrder(orderId);

      if (success) {
        // Remove from cache
        _ordersCache.removeWhere((order) => order.id == orderId);
        _orderDetailsCache.remove(orderId);
      }

      return success;
    } catch (e) {
      debugPrint('OrderRepository.cancelOrder error: $e');
      rethrow;
    }
  }

  /// Convert DTO to Entity
  OrderEntity _dtoToEntity(OrderDto dto) {
    return OrderEntity(
      id: dto.id,
      locationId: dto.locationId,
      locationName: dto.locationName,
      status: dto.status,
      items: dto.items
          .map(
            (itemDto) => OrderItemEntity(
              id: itemDto.id,
              productId: itemDto.productId,
              productName: itemDto.productName,
              price: itemDto.price,
              quantity: itemDto.quantity,
              discount: itemDto.discount,
              note: itemDto.note,
            ),
          )
          .toList(),
      subtotal: dto.subtotal,
      discountAmount: dto.discountAmount,
      taxAmount: dto.taxAmount,
      totalAmount: dto.totalAmount,
      note: dto.note,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      invoiceNumber: dto.invoiceNumber,
      invoicedAt: dto.invoicedAt,
    );
  }

  /// Clear all caches
  void clearCache() {
    _ordersCache = [];
    _orderDetailsCache = {};
  }
}
