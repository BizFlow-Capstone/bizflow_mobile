import 'package:equatable/equatable.dart';
import '../../../../core/reference/data/reference_item.dart';
import '../../../../shared/utils/date_formatter.dart';
import 'order_item_dto.dart';

/// Order Status enum
enum OrderStatus {
  pending('pending', 'Chờ thanh toán'),
  completed('completed', 'Đã hoàn thành'),
  cancelled('cancelled', 'Đã hủy');

  final String code;
  final String displayName;

  const OrderStatus(this.code, this.displayName);

  factory OrderStatus.fromCode(String code) {
    return OrderStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Order DTO - Represents the data transfer object for order
class OrderDto extends Equatable {
  final String id;
  final String orderCode;
  final String? customerName;
  final String? customerPhone;
  final String locationId;
  final String locationName;
  final String status; // pending, completed, cancelled
  final String? statusLabel;
  final List<OrderItemDto> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double cashAmount;
  final double bankAmount;
  final double debtAmount;
  final int? debtorId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String? invoiceNumber;
  final String? documentNumber;
  final DateTime? invoicedAt;
  final String? createdByProfileId;
  final String? createdByProfileFullName;

  const OrderDto({
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
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.invoiceNumber,
    this.documentNumber,
    this.invoicedAt,
    this.createdByProfileId,
    this.createdByProfileFullName,
  });

    bool get isDraft => status.toLowerCase() == 'draft';
    bool get isPending =>
      status.toLowerCase() == OrderStatus.pending.code;
    bool get isPublished =>
      status.toLowerCase() == 'published' ||
      status.toLowerCase() == OrderStatus.completed.code;
    bool get isCancelled =>
      status.toLowerCase() == OrderStatus.cancelled.code;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    DateTime? parseDate(dynamic value) {
      return DateFormatter.parseApiDateTime(value?.toString());
    }

    final rawStatus = json['status'];

    return OrderDto(
      id: asString(json['id'] ?? json['orderId']),
      orderCode: asString(json['orderCode']),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      locationId: asString(
        json['locationId'] ?? json['businessLocationId'],
      ),
      locationName: asString(json['locationName'] ?? json['businessLocationName']),
        status: referenceCodeFromDynamic(rawStatus, fallback: 'pending')
          .toLowerCase(),
        statusLabel: referenceLabelFromDynamic(rawStatus),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => OrderItemDto.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      subtotal: asDouble(json['subtotal'] ?? json['subTotal']),
      discountAmount: asDouble(json['discountAmount'] ?? json['discount']),
      taxAmount: asDouble(json['taxAmount'] ?? json['tax']),
      totalAmount: asDouble(json['totalAmount'] ?? json['total']),
      cashAmount: asDouble(json['cashAmount']),
      bankAmount: asDouble(json['bankAmount']),
      debtAmount: asDouble(json['debtAmount']),
      debtorId: json['debtorId'] as int?,
      note: json['note']?.toString(),
      createdAt:
          parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt:
          parseDate(json['updatedAt']) ?? DateTime.now().toUtc(),
      completedAt: parseDate(json['completedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      createdByProfileId: json['createdByProfileId']?.toString(),
      createdByProfileFullName: json['createdByProfileFullName']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      documentNumber: json['documentNumber']?.toString() ?? json['documentNo']?.toString(),
      invoicedAt: parseDate(json['invoicedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
        'orderCode': orderCode,
        'customerName': customerName,
        'customerPhone': customerPhone,
      'locationId': locationId,
      'locationName': locationName,
      'status': status,
      if ((statusLabel ?? '').trim().isNotEmpty) 'statusLabel': statusLabel,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
        'cashAmount': cashAmount,
        'bankAmount': bankAmount,
        'debtAmount': debtAmount,
        'debtorId': debtorId,
      'note': note,
      'createdAt': DateFormatter.toApiUtcIsoString(createdAt),
      'updatedAt': DateFormatter.toApiUtcIsoString(updatedAt),
        'completedAt': completedAt != null
          ? DateFormatter.toApiUtcIsoString(completedAt!)
          : null,
        'cancelledAt': cancelledAt != null
          ? DateFormatter.toApiUtcIsoString(cancelledAt!)
          : null,
          'createdByProfileId': createdByProfileId,
          'createdByProfileFullName': createdByProfileFullName,
        'cancelReason': cancelReason,
      'invoiceNumber': invoiceNumber,
      if ((documentNumber ?? '').trim().isNotEmpty) 'documentNumber': documentNumber,
      'invoicedAt': invoicedAt != null
          ? DateFormatter.toApiUtcIsoString(invoicedAt!)
          : null,
    };
  }

  OrderDto copyWith({
    String? id,
    String? orderCode,
    String? customerName,
    String? customerPhone,
    String? locationId,
    String? locationName,
    String? status,
    String? statusLabel,
    List<OrderItemDto>? items,
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
    String? documentNumber,
    DateTime? invoicedAt,
  }) {
    return OrderDto(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      documentNumber: documentNumber ?? this.documentNumber,
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
    createdAt,
    updatedAt,
    completedAt,
    cancelledAt,
    cancelReason,
    invoiceNumber,
    documentNumber,
    invoicedAt,
    createdByProfileId,
    createdByProfileFullName,
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
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final dynamic dataNode = json['data'];
    final List<dynamic> rawItems = dataNode is Map<String, dynamic>
      ? (dataNode['items'] as List<dynamic>? ?? const [])
      : (dataNode as List<dynamic>? ?? const []);

    final total = dataNode is Map<String, dynamic>
      ? parseInt(dataNode['totalCount'] ?? dataNode['total'])
      : parseInt(json['totalCount'] ?? json['total']);

    final pageNumber = dataNode is Map<String, dynamic>
      ? parseInt(dataNode['pageNumber'], fallback: 1)
      : parseInt(json['pageNumber'], fallback: 1);

    final pageSize = dataNode is Map<String, dynamic>
      ? parseInt(dataNode['pageSize'], fallback: 20)
      : parseInt(json['pageSize'], fallback: 20);

    return OrderResponseDto(
      orders: rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderDto.fromJson)
        .toList(),
      total: total,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  @override
  List<Object?> get props => [orders, total, pageNumber, pageSize];
}
