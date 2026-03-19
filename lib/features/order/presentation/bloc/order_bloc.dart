import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/order_repository.dart';
import '../../domain/entities/order_entity.dart';
import 'order_event.dart';
import 'order_state.dart';

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
      final orders = await repository.getOrders(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        status: event.status,
        locationId: event.locationId,
      );

      _orders = orders;
      _currentStatusFilter = event.status;
      _currentLocationFilter = event.locationId;

      emit(
        OrdersLoaded(
          orders: orders,
          total: orders.length,
          pageNumber: event.pageNumber,
          pageSize: event.pageSize,
        ),
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
      final orders = await repository.getDraftOrders(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
      );

      _orders = orders;

      emit(DraftOrdersLoaded(orders: orders));
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
      final order = await repository.createOrder(
        locationId: event.locationId,
        items: event.items,
        note: event.note,
      );

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
      final order = await repository.updateOrder(
        orderId: event.orderId,
        note: event.note,
        items: event.items,
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

  /// Publish order
  Future<void> _onPublishOrderRequested(
    PublishOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final order = await repository.publishOrder(event.orderId);

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
      final orders = await repository.getOrders(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        status: event.status,
        locationId: event.locationId,
      );

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

      final orders = await repository.getOrders(
        status: _currentStatusFilter,
        locationId: _currentLocationFilter,
      );

      _orders = orders;

      emit(
        OrdersLoaded(
          orders: orders,
          total: orders.length,
          pageNumber: 1,
          pageSize: 20,
        ),
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
