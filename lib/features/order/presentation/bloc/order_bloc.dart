import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/order_repository.dart';
import '../../domain/entities/order_entity.dart';
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
    on<RefreshOrdersRequested>(_onRefreshOrdersRequested);
    on<ResetOrders>(_onResetOrders);
  }

  /// Load all orders
  Future<void> _onLoadOrdersRequested(
    LoadOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      await repository.getOrdersSWR(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        status: event.status,
        locationId: event.locationId,
        onData: (orders, totalCount, isFromCache) {
          _orders = orders;
          _currentStatusFilter = event.status;
          _currentLocationFilter = event.locationId;
          emit(
            OrdersLoaded(
              orders: orders,
              total: totalCount,
              pageNumber: event.pageNumber,
              pageSize: event.pageSize,
            ),
          );
        },
        onError: (e) {
          emit(OrderError(message: e.toString()));
        },
      );
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Load draft orders
  Future<void> _onLoadDraftOrdersRequested(
    LoadDraftOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      await repository.getOrdersSWR(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        status: 'DRAFT',
        locationId: event.locationId,
        onData: (orders, totalCount, isFromCache) {
          _orders = orders;
          emit(DraftOrdersLoaded(orders: orders));
        },
        onError: (e) {
          emit(OrderError(message: e.toString()));
        },
      );
    } catch (e) {
      emit(OrderError(message: e.toString()));
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
      emit(OrderError(message: e.toString()));
    }
  }

  /// Create new order
  Future<void> _onCreateOrderRequested(
    CreateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      final body = {
        'locationId': event.locationId,
        'items': event.items.map((e) => {
          'productId': e.productId, // This actually should map to SaleItemId if backend says saleItemId, but the DTO accepts saleItemId / productId. I will use what's available.
          // Wait, backend CreateOrderRequest uses SaleItemId
          'saleItemId': int.tryParse(e.productId) ?? 0,
          'quantity': e.quantity,
          'discount': e.discount,
        }).toList(),
        'note': event.note,
      };

      final order = await repository.createOrder(body);

      _orders.insert(0, order);

      emit(OrderCreated(order: order));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Update existing order
  Future<void> _onUpdateOrderRequested(
    UpdateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final body = {
        if (event.note != null) 'note': event.note,
        if (event.items != null) 'items': event.items!.map((e) => {
          'saleItemId': int.tryParse(e.productId) ?? 0,
          'quantity': e.quantity,
          'discount': e.discount,
        }).toList(),
      };

      final order = await repository.updateOrder(
        orderId: event.orderId,
        requestBody: body,
      );

      final index = _orders.indexWhere((o) => o.id == event.orderId);
      if (index != -1) {
        _orders[index] = order;
      }

      emit(OrderUpdated(order: order));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Publish order (now Complete order)
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
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Cancel order
  Future<void> _onCancelOrderRequested(
    CancelOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await repository.cancelOrder(event.orderId);

      _orders.removeWhere((o) => o.id == event.orderId);

      emit(OrderCancelled(orderId: event.orderId));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Filter orders
  Future<void> _onFilterOrdersRequested(
    FilterOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      await repository.getOrdersSWR(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        status: event.status,
        locationId: event.locationId,
        onData: (orders, totalCount, isFromCache) {
          _orders = orders;
          _currentStatusFilter = event.status;
          _currentLocationFilter = event.locationId;
          emit(
            OrdersFiltered(
              orders: orders,
              statusFilter: event.status,
              locationFilter: event.locationId,
            ),
          );
        },
        onError: (e) {
          emit(OrderError(message: e.toString()));
        },
      );
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Refresh orders
  Future<void> _onRefreshOrdersRequested(
    RefreshOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      repository.clearCache();

      await repository.getOrdersSWR(
        pageNumber: 1,
        pageSize: 20,
        status: _currentStatusFilter,
        locationId: event.locationId ?? _currentLocationFilter,
        onData: (orders, totalCount, isFromCache) {
          _orders = orders;
          emit(
            OrdersLoaded(
              orders: orders,
              total: totalCount,
              pageNumber: 1,
              pageSize: 20,
            ),
          );
        },
        onError: (e) {
          emit(OrderError(message: e.toString()));
        },
      );
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  void _onResetOrders(ResetOrders event, Emitter<OrderState> emit) {
    _orders = [];
    _currentStatusFilter = null;
    _currentLocationFilter = null;
    emit(const OrderInitial());
  }
}
