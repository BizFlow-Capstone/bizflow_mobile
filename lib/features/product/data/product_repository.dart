import 'package:flutter/foundation.dart';
import '../domain/entities/product_entity.dart';
import 'product_api_service.dart';

/// Product Repository - Orchestrates product data flow
///
/// Architecture: BLoC → Repository → Service → ApiClient
class ProductRepository {
  final ProductApiService _service;

  ProductRepository({required ProductApiService service}) : _service = service;

  /// Get products for a specific location (Legacy endpoint)
  Future<List<ProductEntity>> getLocationProducts(String locationId) async {
    try {
      final dtos = await _service.getLocationProducts(locationId);
      return dtos
          .map(
            (dto) => ProductEntity(
              id: dto.id,
              name: dto.name,
              description: dto.description,
              price: dto.price,
              costPrice: dto.costPrice,
              salePrice: dto.salePrice,
              quantity: dto.quantity,
              imageUrl: dto.imageUrl,
              businessTypeId: dto.businessTypeId,
              manufacturer: dto.manufacturer,
              saleItems: dto.saleItems,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('ProductRepository.getLocationProducts error: $e');
      rethrow;
    }
  }

  /// Get all products with filters and pagination
  Future<dynamic> getProducts({
    int? locationId,
    String? name,
    String? sku,
    double? minCostPrice,
    double? maxCostPrice,
    int? minStock,
    int? maxStock,
    String? status,
    bool? trackInventory,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await _service.getProducts(
        locationId: locationId,
        name: name,
        sku: sku,
        minCostPrice: minCostPrice,
        maxCostPrice: maxCostPrice,
        minStock: minStock,
        maxStock: maxStock,
        status: status,
        trackInventory: trackInventory,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('ProductRepository.getProducts error: $e');
      rethrow;
    }
  }

  /// Get product detail with images and sale items
  Future<dynamic> getProductDetail(String productId) async {
    try {
      return await _service.getProductDetail(productId);
    } catch (e) {
      debugPrint('ProductRepository.getProductDetail error: $e');
      rethrow;
    }
  }

  /// Get product sale items (price tiers/unit conversions)
  Future<dynamic> getProductSaleItems(String productId) async {
    try {
      return await _service.getProductSaleItems(productId);
    } catch (e) {
      debugPrint('ProductRepository.getProductSaleItems error: $e');
      rethrow;
    }
  }

  /// Create new product
  Future<dynamic> createProduct({
    required String productName,
    required String unit,
    required String businessTypeId, // Required per spec
    required int locationId,
    String? sku,
    bool trackInventory = true,
    double? costPrice,
    double? price,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
  }) async {
    try {
      return await _service.createProduct(
        productName: productName,
        unit: unit,
        businessTypeId: businessTypeId,
        locationId: locationId,
        sku: sku,
        trackInventory: trackInventory,
        costPrice: costPrice,
        price: price,
        stock: stock,
        manufacturer: manufacturer,
        priceTiers: priceTiers,
        imagePath: imagePath,
      );
    } catch (e) {
      debugPrint('ProductRepository.createProduct error: $e');
      rethrow;
    }
  }

  /// Update existing product
  Future<dynamic> updateProduct(
    String productId, {
    required String productName, // Required per spec
    required String unit, // Required per spec
    required int locationId, // Required per spec
    required String businessTypeId, // Required per spec
    String? sku,
    bool? trackInventory,
    double? costPrice,
    double? price,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      return await _service.updateProduct(
        productId,
        productName: productName,
        unit: unit,
        locationId: locationId,
        businessTypeId: businessTypeId,
        sku: sku,
        trackInventory: trackInventory,
        costPrice: costPrice,
        price: price,
        stock: stock,
        manufacturer: manufacturer,
        priceTiers: priceTiers,
        imagePath: imagePath,
        removeImage: removeImage,
      );
    } catch (e) {
      debugPrint('ProductRepository.updateProduct error: $e');
      rethrow;
    }
  }

  /// Update product status (toggle active/inactive)
  Future<dynamic> updateProductStatus(
    String productId, {
    required bool status,
  }) async {
    try {
      return await _service.updateProductStatus(productId, status: status);
    } catch (e) {
      debugPrint('ProductRepository.updateProductStatus error: $e');
      rethrow;
    }
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      return await _service.deleteProduct(productId);
    } catch (e) {
      debugPrint('ProductRepository.deleteProduct error: $e');
      rethrow;
    }
  }

  /// Get business types
  Future<dynamic> getBusinessTypes() async {
    try {
      return await _service.getBusinessTypes();
    } catch (e) {
      debugPrint('ProductRepository.getBusinessTypes error: $e');
      rethrow;
    }
  }
}
