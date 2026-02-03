import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'models/product_dto.dart';

/// Product API Service - Handles product-related API calls
/// 
/// Architecture: BLoC → Repository → Service → ApiClient → Backend
class ProductApiService {
  final ApiClient _apiClient;

  ProductApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get products for a location
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
}
