import 'package:flutter/foundation.dart';
import '../domain/entities/product_entity.dart';
import 'product_api_service.dart';
import 'models/product_dto.dart';
import '../../../shared/cache/cache_manager.dart';
import '../../../shared/context/business_context.dart';

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
              businessLocationName: dto.businessLocationName,
              unit: dto.unit,
              barcode: dto.barcode,
              isActive: dto.isActive,
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
    String? search,
    String? businessTypeId,
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
        search: search,
        businessTypeId: businessTypeId,
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
  Future<ProductEntity?> getProductDetail(String productId) async {
    try {
      final response = await _service.getProductDetail(productId);
      if (response != null &&
          response is Map<String, dynamic> &&
          response['success'] == true &&
          response['data'] != null) {
        final dto = ProductDto.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        return ProductEntity(
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
          businessLocationName: dto.businessLocationName,
          unit: dto.unit,
          barcode: dto.barcode,
          isActive: dto.isActive,
          saleItems: dto.saleItems,
        );
      }
      return null;
    } catch (e) {
      debugPrint('ProductRepository.getProductDetail error: $e');
      rethrow;
    }
  }

  /// Get product sale items (price tiers/unit conversions)
  Future<dynamic> getProductSaleItems(String productId) async {
    final businessId = BusinessContext().currentBusinessId ?? 'all';
    final cacheKey = 'cache_sale_items_${businessId}_$productId';

    final cached = await CacheManager().get(cacheKey);

    try {
      final response = await _service.getProductSaleItems(productId);
      final normalized = _normalizeSaleItems(response);
      await CacheManager().set(cacheKey, {'data': normalized});
      return {'data': normalized};
    } catch (e) {
      debugPrint('ProductRepository.getProductSaleItems error: $e');
      if (cached != null) {
        return {'data': cached['data'] ?? <dynamic>[]};
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _normalizeSaleItems(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic> && data['saleItems'] is List) {
        return (data['saleItems'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    return <Map<String, dynamic>>[];
  }

  /// Get product cost price history
  Future<dynamic> getProductCostPriceHistory(String productId) async {
    try {
      return await _service.getProductCostPriceHistory(productId);
    } catch (e) {
      debugPrint('ProductRepository.getProductCostPriceHistory error: $e');
      rethrow;
    }
  }

  /// Bulk adjust selected sale-item selling prices
  Future<dynamic> bulkAdjustSellingPrice({
    required List<int> saleItemIds,
    required double deltaAmount,
  }) async {
    try {
      return await _service.bulkAdjustSellingPrice(
        saleItemIds: saleItemIds,
        deltaAmount: deltaAmount,
      );
    } catch (e) {
      debugPrint('ProductRepository.bulkAdjustSellingPrice error: $e');
      rethrow;
    }
  }

  /// Adjust product stock manually
  Future<dynamic> adjustProductStock({
    required String productId,
    required int stock,
    String? memo,
    double? costPrice,
  }) async {
    try {
      return await _service.adjustProductStock(
        productId: productId,
        stock: stock,
        memo: memo,
        costPrice: costPrice,
      );
    } catch (e) {
      debugPrint('ProductRepository.adjustProductStock error: $e');
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
