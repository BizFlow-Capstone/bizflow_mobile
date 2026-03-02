import 'package:equatable/equatable.dart';
import 'order_item_entity.dart';

/// Order Entity - Domain model for orders
class OrderEntity extends Equatable {
  final String id;
  final String locationId;
  final String locationName;
  final String status; // DRAFT, PENDING, PUBLISHED, CANCELLED
  final List<OrderItemEntity> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? invoiceNumber;
  final DateTime? invoicedAt;

  const OrderEntity({
    required this.id,
    required this.locationId,
    required this.locationName,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceNumber,
    this.invoicedAt,
  });

  bool get isDraft => status == 'DRAFT';
  bool get isPending => status == 'PENDING';
  bool get isPublished => status == 'PUBLISHED';
  bool get isCancelled => status == 'CANCELLED';

  OrderEntity copyWith({
    String? id,
    String? locationId,
    String? locationName,
    String? status,
    List<OrderItemEntity>? items,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? invoiceNumber,
    DateTime? invoicedAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoicedAt: invoicedAt ?? this.invoicedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    locationId,
    locationName,
    status,
    items,
    subtotal,
    discountAmount,
    taxAmount,
    totalAmount,
    note,
    createdAt,
    updatedAt,
    invoiceNumber,
    invoicedAt,
  ];
}
