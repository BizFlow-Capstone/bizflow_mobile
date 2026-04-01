import 'package:equatable/equatable.dart';

/// Order Item DTO - Represents a single item in an order
class OrderItemDto extends Equatable {
  final String? id;
  final String productId;
  final int? saleItemId;
  final String? unitName;
  final String productName;
  final double price;
  final int quantity;
  final double discount;
  final String? note;

  const OrderItemDto({
    this.id,
    required this.productId,
    this.saleItemId,
    this.unitName,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.discount,
    this.note,
  });

  double get subtotal => price * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return OrderItemDto(
      id: json['id']?.toString(),
      productId: asString(json['productId'] ?? json['saleItemId']),
      saleItemId: asInt(json['saleItemId'], fallback: 0) > 0
          ? asInt(json['saleItemId'])
          : null,
      unitName: asString(
        json['unitName'] ?? json['unit'] ?? json['Unit'] ?? json['baseUnit'],
      ),
      productName: asString(json['productName'] ?? json['saleItemName']),
      price: asDouble(json['price'] ?? json['unitPrice']),
      quantity: asInt(json['quantity']),
      discount: asDouble(json['discount']),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'saleItemId': saleItemId,
      'unitName': unitName,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'discount': discount,
      'note': note,
    };
  }

  OrderItemDto copyWith({
    String? id,
    String? productId,
    int? saleItemId,
    String? unitName,
    String? productName,
    double? price,
    int? quantity,
    double? discount,
    String? note,
  }) {
    return OrderItemDto(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      saleItemId: saleItemId ?? this.saleItemId,
      unitName: unitName ?? this.unitName,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    saleItemId,
    unitName,
    productName,
    price,
    quantity,
    discount,
    note,
  ];
}
