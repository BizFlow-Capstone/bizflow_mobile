import 'package:equatable/equatable.dart';
import 'order_item_entity.dart';

/// Order Entity - Domain model for orders
class OrderEntity extends Equatable {
  final String id;
  final String orderCode;
  final String? customerName;
  final String? customerPhone;
  final String locationId;
  final String locationName;
  final String status; // backend: pending, completed, cancelled
  final String? statusLabel;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double cashAmount;
  final double bankAmount;
  final double debtAmount;
  final int? debtorId;
  final String? note;
  final String? aiConfidence; // 'high', 'medium', 'low' from AI draft
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String? invoiceNumber;
  final DateTime? invoicedAt;
  final String? createdByProfileId;
  final String? createdByProfileFullName;

  const OrderEntity({
    required this.id,
    this.orderCode = '',
    this.customerName,
    this.customerPhone,
    required this.locationId,
    required this.locationName,
    required this.status,
    this.statusLabel,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.cashAmount = 0,
    this.bankAmount = 0,
    this.debtAmount = 0,
    this.debtorId,
    this.note,
    this.aiConfidence,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.invoiceNumber,
    this.invoicedAt,
    this.createdByProfileId,
    this.createdByProfileFullName,
  });

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isPublished =>
      status.toLowerCase() == 'published' || status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  OrderEntity copyWith({
    String? id,
    String? orderCode,
    String? customerName,
    String? customerPhone,
    String? locationId,
    String? locationName,
    String? status,
    String? statusLabel,
    List<OrderItemEntity>? items,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    double? cashAmount,
    double? bankAmount,
    double? debtAmount,
    int? debtorId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelReason,
    String? invoiceNumber,
    DateTime? invoicedAt,
    String? createdByProfileId,
    String? createdByProfileFullName,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      cashAmount: cashAmount ?? this.cashAmount,
      bankAmount: bankAmount ?? this.bankAmount,
      debtAmount: debtAmount ?? this.debtAmount,
      debtorId: debtorId ?? this.debtorId,
      note: note ?? this.note,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoicedAt: invoicedAt ?? this.invoicedAt,
      createdByProfileId: createdByProfileId ?? this.createdByProfileId,
      createdByProfileFullName:
          createdByProfileFullName ?? this.createdByProfileFullName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderCode,
    customerName,
    customerPhone,
    locationId,
    locationName,
    status,
    statusLabel,
    items,
    subtotal,
    discountAmount,
    taxAmount,
    totalAmount,
    cashAmount,
    bankAmount,
    debtAmount,
    debtorId,
    note,
    aiConfidence,
    createdAt,
    updatedAt,
    completedAt,
    cancelledAt,
    cancelReason,
    invoiceNumber,
    invoicedAt,
    createdByProfileId,
    createdByProfileFullName,
  ];
}
