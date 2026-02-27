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
}
