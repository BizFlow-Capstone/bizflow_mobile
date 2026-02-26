import '../domain/entities/order_entity.dart';
import '../domain/entities/order_item_entity.dart';
import 'order_api_service.dart';

/// Mock Order Repository - Returns mock data since API is not ready
///
/// Responsibilities:
/// 1. Provide mock data for order UI creation
/// 2. Handle data transformations and business rules locally
class OrderRepository {
  // ignore: unused_field
  final OrderApiService _apiService; // Kept for DI compatibility

  OrderRepository({required OrderApiService apiService})
    : _apiService = apiService {
    _initMockData();
  }

  // Cache
  List<OrderEntity> _ordersCache = [];
  final Map<String, OrderEntity> _orderDetailsCache = {};

  void _initMockData() {
    final now = DateTime.now();
    _ordersCache = [
      OrderEntity(
        id: '1',
        locationId: '1',
        locationName: 'Shinkiri Tech Store - HCM',
        status: 'DRAFT',
        items: const [
          OrderItemEntity(
            id: 'item1',
            productId: 'prod1',
            productName: 'iPhone 15 Pro Max',
            price: 30000000,
            quantity: 1,
            discount: 0,
          ),
        ],
        subtotal: 30000000,
        discountAmount: 0,
        taxAmount: 3000000,
        totalAmount: 33000000,
        note: 'Khách yêu cầu lấy màu đen',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      OrderEntity(
        id: '2',
        locationId: '4',
        locationName: 'Ngan Beauty Salon',
        status: 'PENDING',
        items: const [
          OrderItemEntity(
            id: 'item2',
            productId: 'prod2',
            productName: 'Mặt nạ dưỡng da',
            price: 500000,
            quantity: 2,
            discount: 10,
          ),
        ],
        subtotal: 1000000,
        discountAmount: 100000,
        taxAmount: 90000,
        totalAmount: 990000,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      OrderEntity(
        id: '3',
        locationId: '1',
        locationName: 'Shinkiri Tech Store - HCM',
        status: 'PUBLISHED',
        items: const [
          OrderItemEntity(
            id: 'item3',
            productId: 'prod3',
            productName: 'MacBook Pro M3',
            price: 45000000,
            quantity: 1,
            discount: 0,
          ),
        ],
        subtotal: 45000000,
        discountAmount: 0,
        taxAmount: 4500000,
        totalAmount: 49500000,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        invoiceNumber: 'INV-2026-001',
        invoicedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Get all orders with optional filters
  Future<List<OrderEntity>> getOrders({
    int pageNumber = 1,
    int pageSize = 20,
    String? status,
    String? locationId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    var filtered = List<OrderEntity>.from(_ordersCache);

    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((o) => o.status == status).toList();
    }

    if (locationId != null && locationId.isNotEmpty) {
      filtered = filtered.where((o) => o.locationId == locationId).toList();
    }

    // Sort descending by updated date
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Simple pagination mock
    final startIndex = (pageNumber - 1) * pageSize;
    if (startIndex >= filtered.length) return [];

    final endIndex = (startIndex + pageSize < filtered.length)
        ? startIndex + pageSize
        : filtered.length;

    return filtered.sublist(startIndex, endIndex);
  }

  /// Get draft orders
  Future<List<OrderEntity>> getDraftOrders({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return getOrders(
      pageNumber: pageNumber,
      pageSize: pageSize,
      status: 'DRAFT',
    );
  }

  /// Get single order by ID
  Future<OrderEntity> getOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      if (_orderDetailsCache.containsKey(orderId)) {
        return _orderDetailsCache[orderId]!;
      }

      final order = _ordersCache.firstWhere((o) => o.id == orderId);
      _orderDetailsCache[orderId] = order;
      return order;
    } catch (e) {
      throw Exception('Order not found');
    }
  }

  /// Create a new order (saves as DRAFT locally)
  Future<OrderEntity> createOrder({
    required String locationId,
    required List<OrderItemEntity> items,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    double subtotal = 0;
    double discountAmount = 0;

    for (var item in items) {
      subtotal += item.price * item.quantity;
      discountAmount += (item.price * item.quantity) * (item.discount / 100);
    }

    final taxAmount = (subtotal - discountAmount) * 0.1; // 10% tax mock
    final totalAmount = subtotal - discountAmount + taxAmount;

    final now = DateTime.now();

    final newOrder = OrderEntity(
      id: 'mock_${now.millisecondsSinceEpoch}',
      locationId: locationId,
      locationName: 'Mock Location',
      status: 'DRAFT',
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    _ordersCache.insert(0, newOrder);
    _orderDetailsCache[newOrder.id] = newOrder;

    return newOrder;
  }

  /// Update an existing order
  Future<OrderEntity> updateOrder({
    required String orderId,
    String? note,
    List<OrderItemEntity>? items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final index = _ordersCache.indexWhere((o) => o.id == orderId);
      if (index == -1) throw Exception('Order not found');

      final existingOrder = _ordersCache[index];

      double subtotal = existingOrder.subtotal;
      double discountAmount = existingOrder.discountAmount;
      double taxAmount = existingOrder.taxAmount;
      double totalAmount = existingOrder.totalAmount;

      // Re-calculate if items changed
      if (items != null) {
        subtotal = 0;
        discountAmount = 0;
        for (var item in items) {
          subtotal += item.price * item.quantity;
          discountAmount +=
              (item.price * item.quantity) * (item.discount / 100);
        }
        taxAmount = (subtotal - discountAmount) * 0.1;
        totalAmount = subtotal - discountAmount + taxAmount;
      }

      final updatedOrder = existingOrder.copyWith(
        note: note ?? existingOrder.note,
        items: items ?? existingOrder.items,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        updatedAt: DateTime.now(),
      );

      _ordersCache[index] = updatedOrder;
      _orderDetailsCache[orderId] = updatedOrder;

      return updatedOrder;
    } catch (e) {
      rethrow;
    }
  }

  /// Publish an order (convert draft to invoice)
  Future<OrderEntity> publishOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final index = _ordersCache.indexWhere((o) => o.id == orderId);
      if (index == -1) throw Exception('Order not found');

      final existingOrder = _ordersCache[index];
      final now = DateTime.now();

      final updatedOrder = existingOrder.copyWith(
        status: 'PUBLISHED',
        updatedAt: now,
        invoiceNumber:
            'INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}',
        invoicedAt: now,
      );

      _ordersCache[index] = updatedOrder;
      _orderDetailsCache[orderId] = updatedOrder;

      return updatedOrder;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _ordersCache.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;

    final order = _ordersCache[index];
    if (order.status == 'DRAFT') {
      // Hard delete draft
      _ordersCache.removeAt(index);
      _orderDetailsCache.remove(orderId);
    } else {
      // Soft cancel
      final updatedOrder = order.copyWith(
        status: 'CANCELLED',
        updatedAt: DateTime.now(),
      );
      _ordersCache[index] = updatedOrder;
      _orderDetailsCache[orderId] = updatedOrder;
    }

    return true;
  }

  /// Clear all caches (keeping mock memory structure intact)
  void clearCache() {
    // For mock setup, we don't nullify _ordersCache
    _orderDetailsCache.clear();
  }
}
