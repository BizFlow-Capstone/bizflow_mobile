import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/order_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import 'order_event.dart';
import 'order_state.dart';

export 'order_event.dart';
export 'order_state.dart';

/// Order BLoC - Manages state and business logic for orders
///
/// Responsibilities:
/// 1. Handle order-related events
/// 2. Call repository to fetch/modify order data
/// 3. Emit states that reflect the current UI state
/// 4. Cache orders in memory for performance
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository repository;

  // Cache variables
  List<OrderEntity> _orders = [];
  List<OrderEntity> _localDrafts = [];
  String? _currentStatusFilter;
  String? _currentLocationFilter;

  OrderBloc({required this.repository}) : super(const OrderInitial()) {
    on<LoadOrdersRequested>(_onLoadOrdersRequested);
    on<LoadDraftOrdersRequested>(_onLoadDraftOrdersRequested);
    on<LoadOrderDetailsRequested>(_onLoadOrderDetailsRequested);
    on<CreateOrderRequested>(_onCreateOrderRequested);
    on<UpdateOrderRequested>(_onUpdateOrderRequested);
    on<PublishOrderRequested>(_onPublishOrderRequested);
    on<CancelOrderRequested>(_onCancelOrderRequested);
    on<FilterOrdersRequested>(_onFilterOrdersRequested);
    on<SearchOrdersRequested>(_onSearchOrdersRequested);
    on<RefreshOrdersRequested>(_onRefreshOrdersRequested);
    on<ResetOrders>(_onResetOrders);
  }

  int _normalizeQuantity(double quantity) {
    if (!quantity.isFinite) return 1;
    return quantity.round().clamp(1, 99999);
  }

  /// Load all orders
  Future<void> _onLoadOrdersRequested(
    LoadOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrdersLoaded) {
      emit(const OrdersLoading());
    }
    try {
      // Load local drafts first, before calling getOrdersSWR
      _localDrafts = await _loadLocalDraftOrders(locationId: event.locationId);

      await repository.getOrdersSWR(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        status: event.status,
        locationId: event.locationId,
        onData: (orders, totalCount, isFromCache) {
          final mergedOrders = _mergeOrdersWithDrafts(orders, event.status);
          _orders = mergedOrders; // This is the master set for the current view
          _currentStatusFilter = event.status;
          _currentLocationFilter = event.locationId;
          
          final filtered = _applyLocalFilters(
            mergedOrders,
            null, // search
            event.status,
          );
          
          emit(
            OrdersLoaded(
              orders: filtered,
              allOrders: mergedOrders,
              total: totalCount,
              pageNumber: event.pageNumber,
              pageSize: event.pageSize,
              statusFilter: event.status,
              locationFilter: event.locationId,
            ),
          );
        },
        onError: (e) {
          emit(OrderError(message: ApiErrorMessageParser.parse(e)));
        },
      );
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Load draft orders
  Future<void> _onLoadDraftOrdersRequested(
    LoadDraftOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! DraftOrdersLoaded) {
      emit(const OrdersLoading());
    }
    try {
      final drafts = await _loadLocalDraftOrders(locationId: event.locationId);
      _orders = drafts;
      emit(DraftOrdersLoaded(orders: drafts));
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Load single order details
  Future<void> _onLoadOrderDetailsRequested(
    LoadOrderDetailsRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderDetailLoading());
    try {
      final order = await repository.getOrder(event.orderId);
      emit(OrderDetailsLoaded(order: order));
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Create new order
  Future<void> _onCreateOrderRequested(
    CreateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      final businessLocationId = int.tryParse(event.locationId);
      if (businessLocationId == null || businessLocationId <= 0) {
        throw Exception('Business location is required');
      }

      final hasInvalidSaleItem = event.items.any(
        (item) => (item.saleItemId ?? 0) <= 0,
      );
      if (hasInvalidSaleItem) {
        throw Exception('Sale item is required for all order items');
      }

      final body = {
        'businessLocationId': businessLocationId,
        'items': event.items
            .map(
              (e) => {
                'productId': e.productId,
                'saleItemId': e.saleItemId,
                'quantity': _normalizeQuantity(e.quantity),
                'discount': e.discount,
              },
            )
            .toList(),
        'cashAmount': event.cashAmount,
        'bankAmount': event.bankAmount,
        'debtAmount': event.debtAmount,
        'note': event.note,
        if (event.documentDate != null)
          'documentDate': event.documentDate!.toIso8601String().split('T')[0],
        if (event.documentNumber != null && event.documentNumber!.isNotEmpty)
          'documentNumber': event.documentNumber,
      };

      final order = await repository.createOrder(body);

      _orders.insert(0, order);

      emit(OrderCreated(order: order));
      add(const RefreshOrdersRequested());
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Update existing order
  Future<void> _onUpdateOrderRequested(
    UpdateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final hasInvalidSaleItem = event.items?.any(
        (item) => (item.saleItemId ?? 0) <= 0,
      );
      if (hasInvalidSaleItem == true) {
        throw Exception('Sale item is required for all order items');
      }

      final body = {
        if (event.note != null) 'note': event.note,
        if (event.status != null) 'status': event.status,
        if (event.businessLocationId != null)
          'businessLocationId': int.tryParse(event.businessLocationId!),
        if (event.cashAmount != null) 'cashAmount': event.cashAmount,
        if (event.bankAmount != null) 'bankAmount': event.bankAmount,
        if (event.debtAmount != null) 'debtAmount': event.debtAmount,
        if (event.debtorId != null) 'debtorId': event.debtorId,
        if (event.customerName != null) 'customerName': event.customerName,
        if (event.customerPhone != null) 'customerPhone': event.customerPhone,
        if (event.billMetadata != null) 'billMetadata': event.billMetadata,
        if (event.items != null)
          'items': event.items!
              .map(
                (e) => {
                  'saleItemId': e.saleItemId,
                  'quantity': _normalizeQuantity(e.quantity),
                  'discount': e.discount,
                },
              )
              .toList(),
      };

      final order = await repository.updateOrder(
        orderId: event.orderId,
        requestBody: body,
        idempotencyKey: event.idempotencyKey,
      );

      final index = _orders.indexWhere((o) => o.id == event.orderId);
      if (index != -1) {
        _orders[index] = order;
      }

      emit(OrderUpdated(order: order));
      add(const RefreshOrdersRequested());
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Publish order (now Complete order)
  void _onSearchOrdersRequested(
    SearchOrdersRequested event,
    Emitter<OrderState> emit,
  ) {
    final s = state;
    if (s is OrdersLoaded) {
      final filtered = _applyLocalFilters(
        s.allOrders,
        event.keyword,
        s.statusFilter,
      );

      emit(s.copyWith(orders: filtered, searchQuery: event.keyword));
    }
  }

  Future<void> _onFilterOrdersRequested(
    FilterOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    final s = state;

    // If only status changed and we already have orders, do it locally
    if (s is OrdersLoaded &&
        event.locationId == s.locationFilter &&
        s.allOrders.isNotEmpty) {
      final filtered = _applyLocalFilters(
        s.allOrders,
        s.searchQuery,
        event.status,
      );

      emit(
        s.copyWith(
          orders: filtered,
          statusFilter: event.status,
          pageNumber: event.pageNumber,
        ),
      );
      return;
    }

    // Otherwise, perform a full reload
    add(
      LoadOrdersRequested(
        locationId: event.locationId,
        status: event.status,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
      ),
    );
  }

  List<OrderEntity> _applyLocalFilters(
    List<OrderEntity> orders,
    String? search,
    String? status,
  ) {
    var result = List<OrderEntity>.from(orders);

    // 1. Status Filter
    if (status != null && status.isNotEmpty && status != 'ALL') {
      result = result.where((o) => o.status.toUpperCase() == status.toUpperCase()).toList();
    }

    // 2. Search Keyword
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      result = result.where((o) {
        final customerName = o.customerName?.toLowerCase() ?? '';
        final customerPhone = o.customerPhone?.toLowerCase() ?? '';
        final orderId = o.id.toString().toLowerCase();
        final orderCode = o.orderCode.toLowerCase();
        
        return customerName.contains(query) ||
               customerPhone.contains(query) ||
               orderId.contains(query) ||
               orderCode.contains(query);
      }).toList();
    }

    return result;
  }

  Future<void> _onPublishOrderRequested(
    PublishOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final order = await repository.completeOrder(event.orderId);

      final index = _orders.indexWhere((o) => o.id == event.orderId);
      if (index != -1) {
        _orders[index] = order;
      }

      emit(OrderPublished(order: order));
      add(const RefreshOrdersRequested());
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  /// Cancel order
  Future<void> _onCancelOrderRequested(
    CancelOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await repository.cancelOrder(
        event.orderId,
        cancelReason: event.cancelReason,
      );

      _orders.removeWhere((o) => o.id == event.orderId);

      emit(OrderCancelled(orderId: event.orderId));
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }


  /// Refresh orders
  Future<void> _onRefreshOrdersRequested(
    RefreshOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrdersLoaded) {
      emit(const OrdersLoading());
    }
    try {
      // Bỏ repository.clearCache() ở đây vì SWR sẽ tự động ghi đè cache mới khi API thành công.
      // Nếu xoá cache trước khi gọi API, khi offline bị rớt mạng sẽ mất luôn danh sách đang lưu tạm.

      // Load local drafts first
      _localDrafts = await _loadLocalDraftOrders(
        locationId: event.locationId ?? _currentLocationFilter,
      );

      await repository.getOrdersSWR(
        pageNumber: 1,
        pageSize: 20,
        status: _currentStatusFilter,
        locationId: event.locationId ?? _currentLocationFilter,
        onData: (orders, totalCount, isFromCache) {
          final mergedOrders = _mergeOrdersWithDrafts(orders, _currentStatusFilter);
          _orders = mergedOrders;
          emit(
            OrdersLoaded(
              allOrders: mergedOrders,
              orders: mergedOrders,
              total: totalCount,
              pageNumber: 1,
              pageSize: 20,
            ),
          );
        },
        onError: (e) {
          emit(OrderError(message: ApiErrorMessageParser.parse(e)));
        },
      );
    } catch (e) {
      emit(OrderError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  void _onResetOrders(ResetOrders event, Emitter<OrderState> emit) {
    _orders = [];
    _currentStatusFilter = null;
    _currentLocationFilter = null;
    emit(const OrderInitial());
  }

  /// Merge local drafts with backend orders, respecting status filters
  List<OrderEntity> _mergeOrdersWithDrafts(
    List<OrderEntity> backendOrders,
    String? statusFilter,
  ) {
    // Only include drafts if filtering for drafts OR no status filter (showing all)
    final shouldIncludeDrafts =
        statusFilter == null || statusFilter.toLowerCase() == 'draft';

    final merged = <OrderEntity>[..._localDrafts, ...backendOrders];
    
    // Filter if statusFilter is specified and not 'draft'
    if (!shouldIncludeDrafts) {
      return merged.where((o) => o.status != 'draft').toList();
    }

    // Sort by updatedAt descending (most recent first)
    merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }

  Future<List<OrderEntity>> _loadLocalDraftOrders({String? locationId}) async {
    final storage = await LocalStorage.getInstance();
    final rawDrafts = storage.getString(StorageKeys.orderLocalDrafts);
    if (rawDrafts == null || rawDrafts.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawDrafts);
    if (decoded is! List) {
      return [];
    }

    final drafts = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
          if (locationId == null || locationId.trim().isEmpty) return true;
          final draftLocationId = (item['locationId'] ?? '').toString();
          return draftLocationId == locationId;
        })
        .map(_mapLocalDraftToOrder)
        .toList();

    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  OrderEntity _mapLocalDraftToOrder(Map<String, dynamic> json) {
    double asDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String asString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      return value.toString();
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
      }
      return DateTime.now().toUtc();
    }

    final itemsNode = json['items'];
    final items = itemsNode is List
        ? itemsNode
            .whereType<Map>()
            .map((item) {
              final map = Map<String, dynamic>.from(item);
              final saleItemRaw = map['saleItemId'];
              int? saleItemId;
              if (saleItemRaw is num) {
                saleItemId = saleItemRaw.toInt();
              } else if (saleItemRaw is String) {
                saleItemId = int.tryParse(saleItemRaw);
              }

              return OrderItemEntity(
                id: asString(map['id'], fallback: ''),
                productId: asString(map['productId']),
                saleItemId: saleItemId,
                unitName: asString(map['unitName'], fallback: ''),
                productName: asString(map['productName']),
                price: asDouble(map['price']),
                quantity: asDouble(map['quantity'], fallback: 1),
                discount: asDouble(map['discount']),
                note: asString(map['note'], fallback: ''),
              );
            })
            .toList()
        : <OrderItemEntity>[];

    return OrderEntity(
      id: asString(
        json['id'],
        fallback: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      ),
      locationId: asString(json['locationId']),
      locationName: asString(json['locationName']),
      status: 'draft',
      items: items,
      subtotal: asDouble(json['subtotal']),
      discountAmount: asDouble(json['discountAmount']),
      taxAmount: asDouble(json['taxAmount']),
      totalAmount: asDouble(json['totalAmount']),
      note: asString(json['note'], fallback: ''),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      invoiceNumber: null,
      invoicedAt: null,
    );
  }
}
