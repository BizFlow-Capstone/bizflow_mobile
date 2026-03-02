import 'package:equatable/equatable.dart';

/// Order Item DTO - Represents a single item in an order
class OrderItemDto extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double discount;
  final String? note;

  const OrderItemDto({
    this.id,
    required this.productId,
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
    return OrderItemDto(
      id: json['id'] as String?,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
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
    String? productName,
    double? price,
    int? quantity,
    double? discount,
    String? note,
  }) {
    return OrderItemDto(
      id: id ?? this.id,
      productId: productId ?? this.productId,
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
    productName,
    price,
    quantity,
    discount,
    note,
  ];
}
