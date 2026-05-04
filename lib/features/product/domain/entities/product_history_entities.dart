import '../../../../shared/utils/date_formatter.dart';

class ProductPricePolicyEntity {
  final int id;
  final double price;
  final bool isDefault;
  final DateTime? startAt;
  final DateTime? endAt;

  ProductPricePolicyEntity({
    required this.id,
    required this.price,
    required this.isDefault,
    this.startAt,
    this.endAt,
  });

  factory ProductPricePolicyEntity.fromMap(Map<String, dynamic> map) {
    return ProductPricePolicyEntity(
      id: map['productPricePolicyId'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isDefault: map['isDefault'] ?? false,
      startAt: DateFormatter.parseApiDateTime(map['startAt']),
      endAt: DateFormatter.parseApiDateTime(map['endAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productPricePolicyId': id,
      'price': price,
      'isDefault': isDefault,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
    };
  }
}

class ProductSaleItemHistoryEntity {
  final int saleItemId;
  final String unit;
  final double quantity;
  final List<ProductPricePolicyEntity> pricePolicies;

  ProductSaleItemHistoryEntity({
    required this.saleItemId,
    required this.unit,
    required this.quantity,
    required this.pricePolicies,
  });

  factory ProductSaleItemHistoryEntity.fromMap(Map<String, dynamic> map) {
    return ProductSaleItemHistoryEntity(
      saleItemId: map['saleItemId'] ?? 0,
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      pricePolicies: (map['pricePolicies'] as List<dynamic>?)
              ?.map((e) => ProductPricePolicyEntity.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'saleItemId': saleItemId,
      'unit': unit,
      'quantity': quantity,
      'pricePolicies': pricePolicies.map((e) => e.toMap()).toList(),
    };
  }
}

class ProductStockMovementEntity {
  final int id;
  final int productId;
  final String movementType; // IN, OUT
  final double quantity;
  final String? referenceType; // ORDER, IMPORT, ADJUSTMENT
  final int? referenceId;
  final String? memo;
  final double balanceAfter;
  final DateTime? createdAt;

  ProductStockMovementEntity({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.memo,
    required this.balanceAfter,
    this.createdAt,
  });

  factory ProductStockMovementEntity.fromMap(Map<String, dynamic> map) {
    return ProductStockMovementEntity(
      id: map['stockMovementId'] ?? 0,
      productId: map['productId'] ?? 0,
      movementType: map['movementType'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      referenceType: map['referenceType'],
      referenceId: map['referenceId'],
      memo: map['memo'],
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateFormatter.parseApiDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stockMovementId': id,
      'productId': productId,
      'movementType': movementType,
      'quantity': quantity,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'memo': memo,
      'balanceAfter': balanceAfter,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Getters for UI compatibility
  double get quantityChange => quantity;
  String get action => movementType;
  String get unit => ''; // Placeholder, usually handled by UI or passed down
  String? get referenceCode => referenceId?.toString();
  String? get notes => memo;

  String get actionLabel {
    switch (movementType.toUpperCase()) {
      case 'IN':
        if (referenceType?.toUpperCase() == 'IMPORT') {
          return 'product.detail.movement_in';
        }
        if (referenceType?.toUpperCase() == 'ADJUSTMENT') {
          return 'product.detail.movement_adjustment_in';
        }
        return 'product.detail.movement_in';
      case 'OUT':
        if (referenceType?.toUpperCase() == 'ORDER') {
          return 'product.detail.movement_sale';
        }
        if (referenceType?.toUpperCase() == 'ADJUSTMENT') {
          return 'product.detail.movement_adjustment_out';
        }
        return 'product.detail.movement_out';
      default:
        return movementType;
    }
  }
}
