import 'package:equatable/equatable.dart';

/// Order Item Entity - Domain model
class OrderItemEntity extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double discount;
  final String? note;

  const OrderItemEntity({
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
