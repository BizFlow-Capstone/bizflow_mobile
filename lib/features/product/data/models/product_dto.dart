import 'package:flutter/foundation.dart';

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
  final double price; // Legacy field, kept for compatibility
  final double? costPrice;
  final double? salePrice;
  final int quantity;
  final String? imageUrl;
  final int? locationId;
  final String? businessTypeId;
  final String? manufacturer;
  final String? businessLocationName;
  final String? unit;
  final String? barcode;
  final bool isActive;
  final List<Map<String, dynamic>> saleItems;

  ProductDto({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.costPrice,
    this.salePrice,
    required this.quantity,
    this.imageUrl,
    this.locationId,
    this.businessTypeId,
    this.manufacturer,
    this.businessLocationName,
    this.unit,
    this.barcode,
    this.isActive = true,
    this.saleItems = const [],
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    debugPrint('ProductDto.fromJson raw data: $json');

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final normalized = value.trim();
        if (normalized.isEmpty) return null;
        return double.tryParse(normalized);
      }
      return null;
    }

    final dynamic idValue =
        json['id'] ??
        json['Id'] ??
        json['ID'] ??
        json['productId'] ??
        json['ProductId'];

    // API may return 'price' as the selling price and 'stock' as inventory
    final dynamic rawSalePrice =
        json['sellingPrice'] ??
        json['SellingPrice'] ??
        json['salePrice'] ??
        json['SalePrice'] ??
        json['sale_price'] ??
        json['currentSalePrice'] ??
        json['CurrentSalePrice'] ??
        json['price'] ??
        json['Price'] ??
        json['unitPrice'] ??
        json['UnitPrice'];
    double resolvedSalePrice = parseDouble(rawSalePrice);

    final dynamic rawCostPrice =
        json['costPrice'] ??
        json['CostPrice'] ??
        json['cost_price'] ??
        json['currentCostPrice'] ??
        json['CurrentCostPrice'] ??
        json['purchasePrice'] ??
        json['PurchasePrice'] ??
        json['purchase_price'] ??
        json['importPrice'] ??
        json['ImportPrice'] ??
        json['import_price'];
    final double? resolvedCostPrice = parseNullableDouble(rawCostPrice);

    // 'stock' is the inventory field from the list API
    final dynamic rawQty =
        json['stock'] ??
        json['Stock'] ??
        json['quantity'] ??
        json['Quantity'] ??
        json['currentStock'] ??
        json['stock_quantity'];
    final int resolvedQty = (rawQty as num?)?.toInt() ?? 0;

    final List<Map<String, dynamic>> saleItems =
        (json['saleItems'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const [];

    // Prioritize salePrice and unit from saleItems where unit matches top-level unit
    String? finalUnit = (json['unit'] ?? json['Unit']) as String?;

    if (saleItems.isNotEmpty && finalUnit != null) {
      // Find the sale item that matches the base unit
      final baseItem = saleItems.firstWhere(
        (item) => (item['unit'] ?? item['Unit']) == finalUnit,
        orElse: () => const {},
      );

      if (baseItem.isNotEmpty) {
        final basePrice = parseDouble(baseItem['price'] ?? baseItem['Price']);
        if (basePrice > 0) {
          resolvedSalePrice = basePrice;
        }
      }
    }

    return ProductDto(
      id: idValue?.toString() ?? '',
      name:
          (json['name'] ??
                  json['Name'] ??
                  json['productName'] ??
                  json['ProductName'] ??
                  json['product_name'])
              as String? ??
          '',
      description: (json['description'] ?? json['Description']) as String?,
      price: resolvedSalePrice,
      salePrice: resolvedSalePrice > 0 ? resolvedSalePrice : null,
      costPrice: resolvedCostPrice,
      quantity: resolvedQty,
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
      businessLocationName:
          (json['businessLocationName'] ?? json['BusinessLocationName'])
              as String?,
      unit: finalUnit,
      barcode:
          (json['sku'] ?? json['Sku'] ?? json['barcode'] ?? json['Barcode'])
              as String?,
      isActive:
          (json['status'] ?? json['Status']) == 'active' ||
          (json['isActive'] ?? json['IsActive']) == true,
      saleItems: saleItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (locationId != null) 'locationId': locationId,
      if (businessTypeId != null) 'businessTypeId': businessTypeId,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (businessLocationName != null)
        'businessLocationName': businessLocationName,
      if (unit != null) 'unit': unit,
      if (barcode != null) 'barcode': barcode,
      'isActive': isActive,
      'saleItems': saleItems,
    };
  }
}
