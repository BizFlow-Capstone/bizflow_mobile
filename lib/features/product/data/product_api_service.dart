import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_error_message_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/multipart_auth_helper.dart';
import 'models/product_dto.dart';
import 'models/business_type_model.dart';

/// Product API Service - Handles product-related API calls
///
/// Architecture: BLoC → Repository → Service → ApiClient → Backend
class ProductApiService {
  final ApiClient _apiClient;
  late final MultipartAuthHelper _multipartAuth;

  ProductApiService({required ApiClient apiClient}) : _apiClient = apiClient {
    _multipartAuth = MultipartAuthHelper(apiClient: _apiClient);
  }

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
        throw Exception('Session expired');
      }
      rethrow;
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
      debugPrint('=== GET PRODUCTS REQUEST ===');
      debugPrint(
        'Filters: search=$search, businessTypeId=$businessTypeId, status=$status',
      );
      debugPrint('Pagination: page=$pageNumber, size=$pageSize');

      final queryParams = <String, dynamic>{
        'PageNumber': pageNumber,
        'PageSize': pageSize,
        if (locationId != null) 'LocationId': locationId,
        if (search != null) 'Search': search,
        if (businessTypeId != null) 'BusinessTypeId': businessTypeId,
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
      rethrow;
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
      rethrow;
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
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService.getProductSaleItems error: $e');
      rethrow;
    }
  }

  /// Get product cost price history from confirmed imports
  ///
  /// API: GET /api/my-business/product/{productId}/cost-price-history
  Future<dynamic> getProductCostPriceHistory(String productId) async {
    try {
      debugPrint('=== GET PRODUCT COST PRICE HISTORY REQUEST ===');
      debugPrint('ProductId: $productId');

      final response = await _apiClient.get(
        ApiEndpoints.getProductCostPriceHistory(productId),
      );

      debugPrint('=== GET PRODUCT COST PRICE HISTORY RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        return response.data;
      }

      throw Exception(response.message ?? 'Failed to load cost price history');
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Only owner can view cost history');
      } else if (e.statusCode == 404) {
        throw Exception('Product not found');
      }
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService.getProductCostPriceHistory error: $e');
      rethrow;
    }
  }

  /// Bulk adjust selected sale-item selling prices
  ///
  /// API: PATCH /api/my-business/products/sale-items/selling-price
  Future<dynamic> bulkAdjustSellingPrice({
    required List<int> saleItemIds,
    required double deltaAmount,
  }) async {
    try {
      debugPrint('=== BULK ADJUST SELLING PRICE REQUEST ===');
      debugPrint('saleItemIds: $saleItemIds');
      debugPrint('deltaAmount: $deltaAmount');

      final response = await _apiClient.patch(
        ApiEndpoints.bulkAdjustSellingPrice,
        body: {'deltaAmount': deltaAmount, 'saleItemIds': saleItemIds},
      );

      debugPrint('=== BULK ADJUST SELLING PRICE RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.isSuccess) {
        return response.data;
      }

      throw Exception(response.message ?? 'Failed to adjust selling prices');
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Only owner can adjust prices');
      }
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService.bulkAdjustSellingPrice error: $e');
      rethrow;
    }
  }

  /// Manual stock adjustment with optional memo and cost price
  ///
  /// API: PATCH /api/my-business/product/{productId}/stock
  Future<dynamic> adjustProductStock({
    required String productId,
    required double stock,
    String? memo,
    double? costPrice,
  }) async {
    try {
      debugPrint('=== ADJUST PRODUCT STOCK REQUEST ===');
      debugPrint('productId: $productId, stock: $stock');

      final Map<String, dynamic> body = {
        'stock': stock,
        if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
        if (costPrice != null) 'costPrice': costPrice,
      };

      final response = await _apiClient.patch(
        ApiEndpoints.adjustProductStock(productId),
        body: body,
      );

      debugPrint('=== ADJUST PRODUCT STOCK RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.isSuccess) {
        return response.data;
      }

      throw Exception(response.message ?? 'Failed to adjust product stock');
    } on ApiException catch (e) {
      debugPrint(
        'ApiException - StatusCode: ${e.statusCode}, Message: ${e.message}',
      );
      if (e.statusCode == 403) {
        throw Exception('Permission denied: Only owner can adjust stock');
      } else if (e.statusCode == 404) {
        throw Exception('Product not found');
      }
      rethrow;
    } catch (e) {
      debugPrint('ProductApiService.adjustProductStock error: $e');
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
    double? price,
    double? stock,
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
        price: price,
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
    double? price,
    double? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
  }) async {
    try {
      debugPrint('=== CREATE PRODUCT MULTIPART ===');

      // Include only additional unit conversions in PriceTiers
      final List<Map<String, dynamic>> finalPriceTiers = [];

      if (priceTiers != null) {
        for (var tier in priceTiers) {
          final tierUnit = tier['Unit'] ?? tier['unit'];
          final tierQty = tier['Quantity'] ?? tier['quantity'];

          // Skip if it's the base unit - handled by SellingPrice
          if ((tierUnit == unit) && (tierQty == 1 || tierQty == 1.0)) {
            continue;
          }

          // Ensure PascalCase keys for the JSON string
          finalPriceTiers.add({
            'Unit': tierUnit,
            'Quantity': tierQty,
            'Price': tier['Price'] ?? tier['price'],
          });
        }
      }

      final Map<String, dynamic> dataMap = {
        'ProductName': productName,
        'Unit': unit,
        'BusinessTypeId': businessTypeId,
        'LocationId': locationId,
        'TrackInventory': trackInventory,
        if (sku != null) 'Sku': sku,
        if (price != null) 'SellingPrice': price,
        if (costPrice != null) 'CostPrice': costPrice,
        if (stock != null) 'Stock': stock,
        if (manufacturer != null) 'Manufacturer': manufacturer,
        if (finalPriceTiers.isNotEmpty)
          'PriceTiers': jsonEncode(finalPriceTiers),
      };

      debugPrint('DataMap: $dataMap');

      final baseUrl = _apiClient.baseUrl;
      final imageFile = (imagePath != null && imagePath.isNotEmpty)
          ? File(imagePath)
          : null;
      final imageBytes = (imageFile != null && imageFile.existsSync())
          ? await imageFile.readAsBytes()
          : null;

      Future<FormData> buildFormData() async {
        final requestMap = Map<String, dynamic>.from(dataMap);
        if (imageBytes != null) {
          requestMap['image'] = MultipartFile.fromBytes(
            imageBytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
        return FormData.fromMap(requestMap);
      }

      Future<Response<dynamic>> sendCreate(Dio dio) async {
        final formData = await buildFormData();
        return dio.post(
          '$baseUrl${ApiEndpoints.createProduct}',
          data: formData,
        );
      }

      final response = await _multipartAuth.executeWithRefresh(send: sendCreate);

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
      debugPrint(
        'DioException [${e.response?.statusCode}]: ${e.response?.data}',
      );
      throw Exception(ApiErrorMessageParser.parse(e));
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
    double? price,
    double? stock,
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
        price: price,
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
    double? price,
    double? stock,
    String? manufacturer,
    List<Map<String, dynamic>>? priceTiers,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      debugPrint('=== UPDATE PRODUCT MULTIPART ===');

      // Include only additional unit conversions in PriceTiers
      final List<Map<String, dynamic>> finalPriceTiers = [];

      if (priceTiers != null) {
        for (var tier in priceTiers) {
          final tierUnit = tier['Unit'] ?? tier['unit'];
          final tierQty = tier['Quantity'] ?? tier['quantity'];

          if ((tierUnit == unit) && (tierQty == 1 || tierQty == 1.0)) {
            continue;
          }

          finalPriceTiers.add({
            'Unit': tierUnit,
            'Quantity': tierQty,
            'Price': tier['Price'] ?? tier['price'],
          });
        }
      }

      final Map<String, dynamic> dataMap = {
        'ProductName': productName,
        'Unit': unit,
        'LocationId': locationId,
        'BusinessTypeId': businessTypeId,
        'RemoveImage': removeImage,
        if (sku != null) 'Sku': sku,
        if (trackInventory != null) 'TrackInventory': trackInventory,
        if (price != null) 'SellingPrice': price,
        if (costPrice != null) 'CostPrice': costPrice,
        if (stock != null) 'Stock': stock,
        if (manufacturer != null) 'Manufacturer': manufacturer,
        if (finalPriceTiers.isNotEmpty)
          'PriceTiers': jsonEncode(finalPriceTiers),
      };

      debugPrint('DataMap: $dataMap');

      final baseUrl = _apiClient.baseUrl;
      final imageFile = (imagePath != null && imagePath.isNotEmpty)
          ? File(imagePath)
          : null;
      final imageBytes = (imageFile != null && imageFile.existsSync())
          ? await imageFile.readAsBytes()
          : null;

      Future<FormData> buildFormData() async {
        final requestMap = Map<String, dynamic>.from(dataMap);
        if (imageBytes != null) {
          requestMap['image'] = MultipartFile.fromBytes(
            imageBytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
        return FormData.fromMap(requestMap);
      }

      Future<Response<dynamic>> sendUpdate(Dio dio) async {
        final formData = await buildFormData();
        return dio.put(
          '$baseUrl${ApiEndpoints.updateProduct(productId)}',
          data: formData,
        );
      }

      final response = await _multipartAuth.executeWithRefresh(send: sendUpdate);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Update failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.response?.data}');
      throw Exception(ApiErrorMessageParser.parse(e));
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

      final response = await _apiClient.patch(
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
      rethrow;
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
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('ProductApiService.deleteProduct error: $e');
      rethrow;
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
        final dataNode = data['data'];
        List<dynamic> list;
        if (dataNode is List) {
          list = dataNode;
        } else if (dataNode is Map<String, dynamic>) {
          list = (dataNode['items'] as List<dynamic>?) ?? <dynamic>[];
        } else {
          list = <dynamic>[];
        }
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
