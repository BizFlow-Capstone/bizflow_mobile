import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/product_dto.dart';
import 'models/business_type_model.dart';

/// Product API Service - Handles product-related API calls
///
/// Architecture: BLoC → Repository → Service → ApiClient → Backend
class ProductApiService {
  final ApiClient _apiClient;

  ProductApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get products for a location (Legacy endpoint)
  ///
  /// API: GET /api/location/{locationId}/products
  Future<List<ProductDto>> getLocationProducts(String locationId) async {
    try {
      final response = await _apiClient.get(
        '/api/location/$locationId/products',
      );

      if (response.isSuccess && response.data != null) {
        final dto = ProductResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        return dto.products;
      } else {
        throw Exception(response.message ?? 'Failed to load products');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('🔒 Session expired');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('ProductApiService.getLocationProducts error: $e');
      rethrow;
    }
  }

  /// Get all products with filters and pagination
  ///
  /// API: GET /api/my-business/products
  /// Supports filtering by: name, SKU, status, business type, price range, stock range
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
      debugPrint('=== GET PRODUCTS REQUEST ===');
      debugPrint('Filters: name=$name, sku=$sku, status=$status');
      debugPrint('Pagination: page=$pageNumber, size=$pageSize');

      final queryParams = <String, dynamic>{
        'PageNumber': pageNumber,
        'PageSize': pageSize,
        if (locationId != null) 'LocationId': locationId,
        if (name != null) 'Name': name,
        if (sku != null) 'Sku': sku,
        if (minCostPrice != null) 'MinCostPrice': minCostPrice,
        if (maxCostPrice != null) 'MaxCostPrice': maxCostPrice,
        if (minStock != null) 'MinStock': minStock,
        if (maxStock != null) 'MaxStock': maxStock,
        if (status != null) 'Status': status,
        if (trackInventory != null) 'TrackInventory': trackInventory,
      };

      final response = await _apiClient.get(
        ApiEndpoints.products,
        queryParams: queryParams,
      );

      debugPrint('=== GET PRODUCTS RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to load products');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Access to products');
      } else if (e.statusCode == 404) {
        throw Exception('Products not found');
      }
      throw Exception('Error loading products: ${e.message}');
    } catch (e) {
      debugPrint('ProductApiService.getProducts error: $e');
      rethrow;
    }
  }

  /// Get product detail with images and sale items
  ///
  /// API: GET /api/my-business/product/{productId}
  Future<dynamic> getProductDetail(String productId) async {
    try {
      debugPrint('=== GET PRODUCT DETAIL REQUEST ===');
      debugPrint('ProductId: $productId');

      final response = await _apiClient.get(
        ApiEndpoints.getProductDetail(productId),
      );

      debugPrint('=== GET PRODUCT DETAIL RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to load product detail');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Cannot access this product');
      } else if (e.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Error loading product detail: ${e.message}');
    } catch (e) {
      debugPrint('ProductApiService.getProductDetail error: $e');
      rethrow;
    }
  }

  /// Get product sale items (price tiers/unit conversions)
  ///
  /// API: GET /api/my-business/product/{productId}/sale-items
  Future<dynamic> getProductSaleItems(String productId) async {
    try {
      debugPrint('=== GET PRODUCT SALE ITEMS REQUEST ===');
      debugPrint('ProductId: $productId');

      final response = await _apiClient.get(
        ApiEndpoints.getProductSaleItems(productId),
      );

      debugPrint('=== GET PRODUCT SALE ITEMS RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to load sale items');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Cannot access this product');
      } else if (e.statusCode == 404) {
        throw Exception('Product or sale items not found');
      }
      throw Exception('Error loading sale items: ${e.message}');
    } catch (e) {
      debugPrint('ProductApiService.getProductSaleItems error: $e');
      rethrow;
    }
  }

  /// Create new product with image and price tiers
  ///
  /// API: POST /api/my-business/product
  /// Note: PriceTiers should be encoded as JSON string array
  /// If imagePath is provided, uses multipart/form-data, otherwise uses JSON
  Future<dynamic> createProduct({
    required String productName,
    required String unit,
    required String businessTypeId, // Mandatory per spec
    required int locationId,
    String? sku,
    bool trackInventory = true,
    double? costPrice,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
  }) async {
    try {
      debugPrint('=== CREATE PRODUCT REQUEST ===');
      debugPrint('Product: $productName, Unit: $unit');
      debugPrint('Location: $locationId, BusinessType: $businessTypeId');

      // Convert price tiers to lowercase keys as per schema
      final convertedPriceTiers = _convertPriceTiers(priceTiers);

      // Use multipart/form-data as required by endpoint.md (fixes 415 error)
      return await _createProductWithImage(
        productName: productName,
        unit: unit,
        businessTypeId: businessTypeId,
        locationId: locationId,
        sku: sku,
        trackInventory: trackInventory,
        costPrice: costPrice,
        stock: stock,
        manufacturer: manufacturer,
        priceTiers: convertedPriceTiers,
        imagePath: imagePath,
      );
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService.createProduct error: $e');
      rethrow;
    }
  }

  /// Helper method to create product with multipart image upload
  Future<dynamic> _createProductWithImage({
    required String productName,
    required String unit,
    required String businessTypeId,
    required int locationId,
    String? sku,
    bool trackInventory = true,
    double? costPrice,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
  }) async {
    try {
      debugPrint('=== CREATE PRODUCT MULTIPART ===');

      final Map<String, dynamic> dataMap = {
        'ProductName': productName,
        'Unit': unit,
        'BusinessTypeId': businessTypeId,
        'LocationId': locationId,
        'TrackInventory': trackInventory,
        if (sku != null) 'Sku': sku,
        if (costPrice != null) 'CostPrice': costPrice,
        if (stock != null) 'Stock': stock,
        if (manufacturer != null) 'Manufacturer': manufacturer,
        // PriceTiers as JSON string per description
        if (priceTiers != null && priceTiers.isNotEmpty)
          'PriceTiers': jsonEncode(priceTiers),
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);
        if (imageFile.existsSync()) {
          final imageBytes = await imageFile.readAsBytes();
          dataMap['image'] = MultipartFile.fromBytes(
            imageBytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      final formData = FormData.fromMap(dataMap);

      final dio = Dio();
      final baseUrl = _apiClient.baseUrl;
      dio.options.headers = {'Accept-Language': 'en'};

      // SSL Bypass
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
            client.badCertificateCallback = (cert, host, port) => true;
            return client;
          };

      final response = await dio.post(
        '$baseUrl${ApiEndpoints.createProduct}',
        data: formData,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data;
      } else {
        throw Exception(
          response.statusMessage ?? 'Failed to create product with image',
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService._createProductWithImage error: $e');
      rethrow;
    }
  }

  /// Update existing product
  /// API: PUT /api/my-business/product/{productId}
  Future<dynamic> updateProduct(
    String productId, {
    required String productName, // Mandatory per spec
    required String unit, // Mandatory per spec
    required int locationId, // Mandatory per spec
    required String businessTypeId, // Mandatory per spec
    String? sku,
    bool? trackInventory,
    double? costPrice,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      debugPrint('=== UPDATE PRODUCT REQUEST ===');
      debugPrint('ProductId: $productId, BusinessTypeId: $businessTypeId');

      // Convert price tiers to lowercase keys as per schema
      final convertedPriceTiers = _convertPriceTiers(priceTiers);

      // Always use multipart/form-data as required by endpoint.md (fixes 415 error)
      return await _updateProductWithImage(
        productId,
        productName: productName,
        unit: unit,
        locationId: locationId,
        businessTypeId: businessTypeId,
        sku: sku,
        trackInventory: trackInventory,
        costPrice: costPrice,
        stock: stock,
        manufacturer: manufacturer,
        priceTiers: convertedPriceTiers,
        imagePath: imagePath,
        removeImage: removeImage,
      );
    } on ApiException catch (e) {
      debugPrint('ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService.updateProduct error: $e');
      rethrow;
    }
  }

  /// Update product with image upload via multipart/form-data
  Future<dynamic> _updateProductWithImage(
    String productId, {
    required String productName,
    required String unit,
    required int locationId,
    required String businessTypeId,
    String? sku,
    bool? trackInventory,
    double? costPrice,
    int? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      debugPrint('=== UPDATE PRODUCT MULTIPART ===');

      final Map<String, dynamic> dataMap = {
        'ProductName': productName,
        'Unit': unit,
        'LocationId': locationId,
        'BusinessTypeId': businessTypeId,
        'RemoveImage': removeImage,
        if (sku != null) 'Sku': sku,
        if (trackInventory != null) 'TrackInventory': trackInventory,
        if (costPrice != null) 'CostPrice': costPrice,
        if (stock != null) 'Stock': stock,
        if (manufacturer != null) 'Manufacturer': manufacturer,
        if (priceTiers != null && priceTiers.isNotEmpty)
          'PriceTiers': jsonEncode(priceTiers),
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);
        if (imageFile.existsSync()) {
          final imageBytes = await imageFile.readAsBytes();
          dataMap['image'] = MultipartFile.fromBytes(
            imageBytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      final formData = FormData.fromMap(dataMap);

      final dio = Dio();
      final baseUrl = _apiClient.baseUrl;
      dio.options.headers = {'Accept-Language': 'en'};

      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
            client.badCertificateCallback = (cert, host, port) => true;
            return client;
          };

      final response = await dio.put(
        '$baseUrl${ApiEndpoints.updateProduct(productId)}',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Update failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService._updateProductWithImage error: $e');
      rethrow;
    }
  }

  /// Helper to convert price tiers keys to lowercase for API
  List<Map<String, dynamic>>? _convertPriceTiers(
    List<Map<String, dynamic>>? tiers,
  ) {
    if (tiers == null) return null;
    return tiers.map((tier) {
      return {
        'unit': tier['Unit'] ?? tier['unit'],
        'quantity': tier['Quantity'] ?? tier['quantity'],
        'price': tier['Price'] ?? tier['price'],
      };
    }).toList();
  }

  /// Update product status (toggle active/inactive)
  ///
  /// API: PUT /api/my-business/product/{productId}/status
  Future<dynamic> updateProductStatus(
    String productId, {
    required bool status,
  }) async {
    try {
      debugPrint('=== UPDATE PRODUCT STATUS REQUEST ===');
      debugPrint('ProductId: $productId (Type: ${productId.runtimeType})');
      debugPrint('Status: $status');

      final body = {'status': status ? 'active' : 'inactive'};
      debugPrint('Request Body: $body');

      final response = await _apiClient.put(
        ApiEndpoints.updateProductStatus(productId),
        body: body,
      );

      debugPrint('=== UPDATE PRODUCT STATUS RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Success: ${response.isSuccess}');
      debugPrint('Response Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to update product status');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception(
          'Permission denied: Only owner can update product status',
        );
      } else if (e.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Error updating product status: ${e.message}');
    } catch (e) {
      debugPrint('ProductApiService.updateProductStatus error: $e');
      rethrow;
    }
  }

  /// Delete product (soft delete - sets DeletedAt timestamp)
  ///
  /// API: DELETE /api/my-business/product/{productId}
  Future<void> deleteProduct(String productId) async {
    try {
      debugPrint('=== DELETE PRODUCT REQUEST ===');
      debugPrint('ProductId: $productId');

      final response = await _apiClient.delete(
        ApiEndpoints.deleteProduct(productId),
      );

      debugPrint('=== DELETE PRODUCT RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to delete product');
      }
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Only owner can delete products');
      } else if (e.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Error deleting product: ${e.message}');
    } catch (e) {
      debugPrint('ProductApiService.deleteProduct error: $e');
      return;
    }
  }

  /// Get Business Types
  Future<List<BusinessTypeDto>> getBusinessTypes() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.businessTypes,
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        final List<dynamic> list = data['data'];
        return list
            .map((e) => BusinessTypeDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('ProductApiService.getBusinessTypes error: $e');
      rethrow;
    }
  }
}
