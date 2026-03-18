/// Stock Import Entity - Domain model for stock import operations
library;

/// Status of a stock import order
enum StockImportStatus {
  draft, // Bản nháp
  contacted, // Đã liên hệ
  completed, // Đã nhập
}

/// Type of stock import
enum StockImportType {
  withInvoice, // Có hóa đơn
  withoutInvoice, // Không hóa đơn
}

/// Single item in a stock import order
class StockImportItemEntity {
  final String productId;
  final String productName;
  final String? supplier;
  int quantity;
  final String unit;
  final double? unitPrice;

  StockImportItemEntity({
    required this.productId,
    required this.productName,
    this.supplier,
    required this.quantity,
    required this.unit,
    this.unitPrice,
  });

  StockImportItemEntity copyWith({
    String? productId,
    String? productName,
    String? supplier,
    int? quantity,
    String? unit,
    double? unitPrice,
  }) {
    return StockImportItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      supplier: supplier ?? this.supplier,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

/// Stock Import Order Entity
class StockImportEntity {
  final String? id;
  final String locationId;
  final StockImportType type;
  final StockImportStatus status;
  final List<StockImportItemEntity> items;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockImportEntity({
    this.id,
    required this.locationId,
    required this.type,
    required this.status,
    required this.items,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  StockImportEntity copyWith({
    String? id,
    String? locationId,
    StockImportType? type,
    StockImportStatus? status,
    List<StockImportItemEntity>? items,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockImportEntity(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      type: type ?? this.type,
      status: status ?? this.status,
      items: items ?? this.items,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate total items count
  int get totalItemsCount => items.length;

  /// Calculate total quantity
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Low stock suggestion for a product
class LowStockSuggestionEntity {
  final String productId;
  final String productName;
  final String? supplier;
  final int currentStock;
  final int minimumStock;
  final String unit;

  LowStockSuggestionEntity({
    required this.productId,
    required this.productName,
    this.supplier,
    required this.currentStock,
    required this.minimumStock,
    required this.unit,
  });

  /// Suggested quantity to order (to reach minimum stock)
  int get suggestedQuantity => minimumStock - currentStock;

  /// Convert to stock import item
  StockImportItemEntity toStockImportItem() {
    return StockImportItemEntity(
      productId: productId,
      productName: productName,
      supplier: supplier,
      quantity: suggestedQuantity,
      unit: unit,
    );
  }
}
