import '../../../../shared/utils/date_formatter.dart';

/// Product Entity - Domain model
class ProductEntity {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final String? unit;
  final bool isActive;
  final String? statusLabel;
  final DateTime? createdAt;
  final int? locationId;
  final String? businessTypeId;
  final String? manufacturer;
  final String? businessLocationName;
  final bool trackInventory;
  final List<Map<String, dynamic>> saleItems;

  ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.unit,
    this.isActive = true,
    this.statusLabel,
    this.createdAt,
    this.locationId,
    this.businessTypeId,
    this.manufacturer,
    this.businessLocationName,
    this.trackInventory = true,
    this.saleItems = const [],
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
    String? barcode,
    String? category,
    double? costPrice,
    double? salePrice,
    String? unit,
    bool? isActive,
    String? statusLabel,
    DateTime? createdAt,
    int? locationId,
    String? businessTypeId,
    String? manufacturer,
    String? businessLocationName,
    bool? trackInventory,
    List<Map<String, dynamic>>? saleItems,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt ?? this.createdAt,
      locationId: locationId ?? this.locationId,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      manufacturer: manufacturer ?? this.manufacturer,
      businessLocationName: businessLocationName ?? this.businessLocationName,
      trackInventory: trackInventory ?? this.trackInventory,
      saleItems: saleItems ?? this.saleItems,
    );
  }

  /// Serialize to Map for CacheManager storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'category': category,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'unit': unit,
      'isActive': isActive,
      'statusLabel': statusLabel,
      'createdAt': createdAt != null
          ? DateFormatter.toApiUtcIsoString(createdAt!)
          : null,
      'locationId': locationId,
      'businessTypeId': businessTypeId,
      'manufacturer': manufacturer,
      'businessLocationName': businessLocationName,
      'trackInventory': trackInventory,
      'saleItems': saleItems,
    };
  }

  /// Deserialize from Map (CacheManager)
  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double? parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value, {bool fallback = true}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
      return fallback;
    }

    final double priceValue = parseDouble(
      map['sellingPrice'] ??
          map['SellingPrice'] ??
          map['sellingPrice'] ??
          map['SellingPrice'] ??
          map['price'] ??
          map['Price'],
    );
    final double? salePriceValue = parseDoubleNullable(
      map['sellingPrice'] ??
          map['SellingPrice'] ??
          map['currentSalePrice'] ??
          map['CurrentSalePrice'] ??
          map['salePrice'] ??
          map['SalePrice'],
    );

    return ProductEntity(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? 'Unknown',
      description: map['description'] as String?,
      price: priceValue,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      barcode: map['barcode'] as String?,
      category: map['category'] as String?,
      costPrice: parseDoubleNullable(
        map['costPrice'] ??
            map['CostPrice'] ??
            map['cost_price'] ??
            map['currentCostPrice'] ??
            map['CurrentCostPrice'] ??
            map['purchasePrice'] ??
            map['PurchasePrice'] ??
            map['purchase_price'] ??
            map['importPrice'] ??
            map['ImportPrice'] ??
            map['import_price'],
      ),
      salePrice: salePriceValue ?? priceValue,
      unit: map['unit'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      statusLabel: map['statusLabel'] as String?,
      createdAt: DateFormatter.parseApiDateTime(map['createdAt'] as String?),
      locationId: map['locationId'] as int?,
      businessTypeId: map['businessTypeId'] as String?,
      manufacturer: map['manufacturer'] as String?,
      businessLocationName: map['businessLocationName'] as String?,
        trackInventory: parseBool(map['trackInventory'], fallback: true),
      saleItems:
          (map['saleItems'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );
  }
}
