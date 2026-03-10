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
  final DateTime? createdAt;
  final int? locationId;
  final String? businessTypeId;
  final String? manufacturer;
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
    this.createdAt,
    this.locationId,
    this.businessTypeId,
    this.manufacturer,
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
    DateTime? createdAt,
    int? locationId,
    String? businessTypeId,
    String? manufacturer,
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
      createdAt: createdAt ?? this.createdAt,
      locationId: locationId ?? this.locationId,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      manufacturer: manufacturer ?? this.manufacturer,
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
      'createdAt': createdAt?.toIso8601String(),
      'locationId': locationId,
      'businessTypeId': businessTypeId,
      'manufacturer': manufacturer,
      'saleItems': saleItems,
    };
  }

  /// Deserialize from Map (CacheManager)
  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? 'Unknown',
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      barcode: map['barcode'] as String?,
      category: map['category'] as String?,
      costPrice: (map['costPrice'] as num?)?.toDouble(),
      salePrice: (map['salePrice'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      locationId: map['locationId'] as int?,
      businessTypeId: map['businessTypeId'] as String?,
      manufacturer: map['manufacturer'] as String?,
      saleItems:
          (map['saleItems'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );
  }
}
