import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

/// Order States - Emitted by BLoC
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// Orders loading
class OrdersLoading extends OrderState {
  const OrdersLoading();
}

/// Orders loaded successfully
class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;
  final int total;
  final int pageNumber;
  final int pageSize;

  const OrdersLoaded({
    required this.orders,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
  });

  @override
  List<Object?> get props => [orders, total, pageNumber, pageSize];
}

/// Draft orders loaded successfully
class DraftOrdersLoaded extends OrderState {
  final List<OrderEntity> orders;

  const DraftOrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

/// Order details loaded
class OrderDetailsLoaded extends OrderState {
  final OrderEntity order;

  const OrderDetailsLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

/// Order created successfully
class OrderCreated extends OrderState {
  final OrderEntity order;

  const OrderCreated({required this.order});

  @override
  List<Object?> get props => [order];
}

/// Order updated successfully
class OrderUpdated extends OrderState {
  final OrderEntity order;

  const OrderUpdated({required this.order});

  @override
  List<Object?> get props => [order];
}

/// Order published successfully
class OrderPublished extends OrderState {
  final OrderEntity order;

  const OrderPublished({required this.order});

  @override
  List<Object?> get props => [order];
}

/// Order cancelled successfully
class OrderCancelled extends OrderState {
  final String orderId;

  const OrderCancelled({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Orders filtered
class OrdersFiltered extends OrderState {
  final List<OrderEntity> orders;
  final String? statusFilter;
  final String? locationFilter;

  const OrdersFiltered({
    required this.orders,
    this.statusFilter,
    this.locationFilter,
  });

  @override
  List<Object?> get props => [orders, statusFilter, locationFilter];
}

/// Error state
class OrderError extends OrderState {
  final String message;

  const OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading state for specific order
class OrderDetailLoading extends OrderState {
  const OrderDetailLoading();
}
