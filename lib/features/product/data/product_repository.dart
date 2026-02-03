import 'package:flutter/foundation.dart';
import '../domain/entities/product_entity.dart';
import 'product_api_service.dart';

/// Product Repository - Orchestrates product data flow
/// 
/// Architecture: BLoC → Repository → Service → ApiClient
class ProductRepository {
  final ProductApiService _service;

  ProductRepository({required ProductApiService service}) : _service = service;

  /// Get products for a specific location
  Future<List<ProductEntity>> getLocationProducts(String locationId) async {
    try {
      final dtos = await _service.getLocationProducts(locationId);
      return dtos
          .map((dto) => ProductEntity(
                id: dto.id,
                name: dto.name,
                description: dto.description,
                price: dto.price,
                quantity: dto.quantity,
                imageUrl: dto.imageUrl,
              ))
          .toList();
    } catch (e) {
      debugPrint('ProductRepository.getLocationProducts error: $e');
      rethrow;
    }
  }
}
