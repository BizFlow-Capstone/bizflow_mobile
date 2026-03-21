import 'package:equatable/equatable.dart';
import '../../../../shared/utils/date_formatter.dart';
import 'order_item_dto.dart';

/// Order Status enum
enum OrderStatus {
  draft('DRAFT', 'Tạm tính'),
  pending('PENDING', 'Chờ xuất'),
  published('PUBLISHED', 'Đã xuất'),
  cancelled('CANCELLED', 'Đã hủy');

  final String code;
  final String displayName;

  const OrderStatus(this.code, this.displayName);

  factory OrderStatus.fromCode(String code) {
    return OrderStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => OrderStatus.draft,
    );
  }
}

/// Order DTO - Represents the data transfer object for order
class OrderDto extends Equatable {
  final String id;
  final String locationId;
  final String locationName;
  final String status; // DRAFT, PENDING, PUBLISHED, CANCELLED
  final List<OrderItemDto> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? invoiceNumber;
  final DateTime? invoicedAt;

  const OrderDto({
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

  bool get isDraft => status == 'DRAFT' || status == OrderStatus.draft.code;
  bool get isPending =>
      status == 'PENDING' || status == OrderStatus.pending.code;
  bool get isPublished =>
      status == 'PUBLISHED' || status == OrderStatus.published.code;
  bool get isCancelled =>
      status == 'CANCELLED' || status == OrderStatus.cancelled.code;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as String? ?? '',
      locationId: json['locationId'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => OrderItemDto.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
        createdAt: DateFormatter.parseApiDateTime(
          json['createdAt'] as String?,
          fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
        updatedAt: DateFormatter.parseApiDateTime(
          json['updatedAt'] as String?,
          fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
      invoiceNumber: json['invoiceNumber'] as String?,
        invoicedAt: DateFormatter.parseApiDateTime(json['invoicedAt'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'locationName': locationName,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'note': note,
      'createdAt': DateFormatter.toApiUtcIsoString(createdAt),
      'updatedAt': DateFormatter.toApiUtcIsoString(updatedAt),
      'invoiceNumber': invoiceNumber,
      'invoicedAt': invoicedAt != null
          ? DateFormatter.toApiUtcIsoString(invoicedAt!)
          : null,
    };
  }

  OrderDto copyWith({
    String? id,
    String? locationId,
    String? locationName,
    String? status,
    List<OrderItemDto>? items,
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
    return OrderDto(
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

/// Order Response DTO - API response wrapper
class OrderResponseDto extends Equatable {
  final List<OrderDto> orders;
  final int total;
  final int pageNumber;
  final int pageSize;

  const OrderResponseDto({
    required this.orders,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
  });

  factory OrderResponseDto.fromJson(Map<String, dynamic> json) {
    return OrderResponseDto(
      orders:
          (json['data'] as List<dynamic>?)
              ?.map((order) => OrderDto.fromJson(order as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  @override
  List<Object?> get props => [orders, total, pageNumber, pageSize];
}
