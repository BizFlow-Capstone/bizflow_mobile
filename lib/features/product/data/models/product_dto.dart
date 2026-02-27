/// Product DTO - Data Transfer Object

/// Product Response from API
class ProductResponseDto {
  final List<ProductDto> products;
  final bool success;
  final String messageCode;
  final String message;

  ProductResponseDto({
    required this.products,
    required this.success,
    required this.messageCode,
    required this.message,
  });

  factory ProductResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    return ProductResponseDto(
      products: data
          .map((item) => ProductDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      success: json['success'] as bool? ?? false,
      messageCode: json['messageCode'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Single Product DTO
class ProductDto {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final int? locationId;
  final String? businessTypeId;
  final String? manufacturer;
  final List<Map<String, dynamic>> saleItems;

  ProductDto({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.locationId,
    this.businessTypeId,
    this.manufacturer,
    this.saleItems = const [],
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final dynamic idValue =
        json['id'] ??
        json['Id'] ??
        json['ID'] ??
        json['productId'] ??
        json['ProductId'];
    return ProductDto(
      id: idValue?.toString() ?? '',
      name:
          (json['name'] ??
                  json['Name'] ??
                  json['productName'] ??
                  json['ProductName'])
              as String? ??
          '',
      description: (json['description'] ?? json['Description']) as String?,
      price:
          (json['price'] as num? ??
                  json['Price'] as num? ??
                  json['costPrice'] as num? ??
                  json['CostPrice'] as num?)
              ?.toDouble() ??
          0.0,
      quantity:
          (json['quantity'] as int? ??
              json['Quantity'] as int? ??
              json['stock'] as int? ??
              json['Stock'] as int?) ??
          0,
      imageUrl:
          (json['imageUrl'] ??
                  json['ImageUrl'] ??
                  json['image'] ??
                  json['Image'])
              as String?,
      locationId: json['locationId'] as int? ?? json['LocationId'] as int?,
      businessTypeId:
          (json['businessTypeId'] ?? json['BusinessTypeId']) as String?,
      manufacturer: (json['manufacturer'] ?? json['Manufacturer']) as String?,
      saleItems:
          (json['saleItems'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (locationId != null) 'locationId': locationId,
      if (businessTypeId != null) 'businessTypeId': businessTypeId,
    };
  }
}
