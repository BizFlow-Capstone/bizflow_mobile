import 'package:equatable/equatable.dart';
import '../../domain/entities/order_item_entity.dart';

/// Order Events - Triggered by UI or app logic
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Load all orders with optional filters
class LoadOrdersRequested extends OrderEvent {
  const LoadOrdersRequested({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.status,
    this.locationId,
  });
  final int pageNumber;
  final int pageSize;
  final String? status; // DRAFT, PENDING, PUBLISHED, CANCELLED
  final String? locationId;

  @override
  List<Object?> get props => [pageNumber, pageSize, status, locationId];
}

/// Reset orders state (on logout)
class ResetOrders extends OrderEvent {
  const ResetOrders();
}

/// Load draft orders only
class LoadDraftOrdersRequested extends OrderEvent {
  final int pageNumber;
  final int pageSize;
  final String? locationId;

  const LoadDraftOrdersRequested({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.locationId,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, locationId];
}

/// Load single order details
class LoadOrderDetailsRequested extends OrderEvent {
  final String orderId;

  const LoadOrderDetailsRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Create new order
class CreateOrderRequested extends OrderEvent {
  final String locationId;
  final List<OrderItemEntity> items;
  final String? note;

  const CreateOrderRequested({
    required this.locationId,
    required this.items,
    this.note,
  });

  @override
  List<Object?> get props => [locationId, items, note];
}

/// Update existing order
class UpdateOrderRequested extends OrderEvent {
  final String orderId;
  final String? note;
  final List<OrderItemEntity>? items;

  const UpdateOrderRequested({required this.orderId, this.note, this.items});

  @override
  List<Object?> get props => [orderId, note, items];
}

/// Publish order (convert draft to invoice)
class PublishOrderRequested extends OrderEvent {
  final String orderId;

  const PublishOrderRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Cancel order
class CancelOrderRequested extends OrderEvent {
  final String orderId;

  const CancelOrderRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Filter orders by status or location
class FilterOrdersRequested extends OrderEvent {
  final String? status;
  final String? locationId;
  final int pageNumber;
  final int pageSize;

  const FilterOrdersRequested({
    this.status,
    this.locationId,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [status, locationId, pageNumber, pageSize];
}

/// Refresh orders
class RefreshOrdersRequested extends OrderEvent {
  final String? locationId;
  const RefreshOrdersRequested({this.locationId});

  @override
  List<Object?> get props => [locationId];
}
