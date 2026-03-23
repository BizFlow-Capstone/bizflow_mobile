import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/order_dto.dart';

/// Order API Service - Handles direct API communication for orders
///
/// Responsibilities:
/// 1. Make HTTP requests via ApiClient
/// 2. Parse raw responses to DTOs
/// 3. Handle API-specific errors
/// 4. Return DTOs to Repository
class OrderApiService {
  final ApiClient _apiClient;

  OrderApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all orders for the current user
  ///
  /// API: GET /api/order/my-orders?pageNumber=1&pageSize=20&status=DRAFT
  /// Returns: OrderResponseDto
  /// Throws: Exception with user-friendly message
  Future<OrderResponseDto> getOrders({
    int pageNumber = 1,
    int pageSize = 20,
    String? status,
    String? locationId,
  }) async {
    try {
      final queryParams = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (status != null) 'status': status,
        if (locationId != null) 'locationId': locationId,
      };

      final response = await _apiClient.get(
        ApiEndpoints.orders,
        queryParams: queryParams,
      );

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Success: ${response.isSuccess}');
      debugPrint('API Response Data Type: ${response.data.runtimeType}');

      if (response.isSuccess && response.data != null) {
        // Check if response.data is Map
        if (response.data is! Map<String, dynamic>) {
          throw Exception(
            'Response không đúng format\n\n'
            'Expected: Map<String, dynamic>\n'
            'Got: ${response.data.runtimeType}\n',
          );
        }

        // Parse raw JSON to DTO
        return OrderResponseDto.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.message ?? 'Failed to load orders');
      }
    } on ApiException catch (e) {
      // Transform ApiException to domain exception with user-friendly messages
      if (e.statusCode == -1) {
        throw Exception(
          'No network connection\n\n'
          'Check:\n'
          '• Is backend running?\n'
          '• Port: 7270\n'
          '• URL: http://192.168.1.9:7270',
        );
      } else if (e.statusCode == -2) {
        throw Exception(
          'Connection timeout\n\n'
          'Backend did not respond within 30 seconds',
        );
      } else if (e.statusCode == -3) {
        throw Exception(
          'Backend connection error\n\n'
          '${e.message}\n\n'
          'Solutions:\n'
          '1. Check backend is running: dotnet run\n'
          '2. Ensure port 7270 is not blocked\n'
          '3. Hot restart app (press R)',
        );
      } else if (e.statusCode == 401) {
        throw Exception('Session expired\n\nPlease login again');
      } else if (e.statusCode == 404) {
        throw Exception('Orders not found');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('OrderApiService.getOrders error: $e');
      rethrow;
    }
  }



  /// Get single order by ID
  ///
  /// API: GET /api/order/{id}
  /// Returns: OrderDto
  Future<OrderDto> getOrder(String orderId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getOrder(orderId));

      if (response.isSuccess && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        final data = response.data as Map<String, dynamic>;
        return OrderDto.fromJson(data['data'] ?? data);
      } else {
        throw Exception(response.message ?? 'Failed to load order');
      }
    } catch (e) {
      debugPrint('OrderApiService.getOrder error: $e');
      rethrow;
    }
  }

  /// Create a new order (pending)
  ///
  /// API: POST /api/my-business/accounting/orders
  /// Returns: OrderDto
  Future<OrderDto> createOrder(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createOrder,
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        final data = response.data as Map<String, dynamic>;
        return OrderDto.fromJson(data['data'] ?? data);
      } else {
        throw Exception(response.message ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('OrderApiService.createOrder error: $e');
      rethrow;
    }
  }

  /// Update an existing order (pending)
  ///
  /// API: PUT /api/my-business/accounting/orders/{id}
  /// Returns: OrderDto
  Future<OrderDto> updateOrder({
    required String orderId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateOrder(orderId),
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        final data = response.data as Map<String, dynamic>;
        return OrderDto.fromJson(data['data'] ?? data);
      } else {
        throw Exception(response.message ?? 'Failed to update order');
      }
    } catch (e) {
      debugPrint('OrderApiService.updateOrder error: $e');
      rethrow;
    }
  }

  /// Complete an order (convert pending to completed)
  ///
  /// API: POST /api/my-business/accounting/orders/{id}/complete
  /// Returns: OrderDto
  Future<OrderDto> completeOrder(String orderId, {bool confirmLowStock = false}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.completeOrder(orderId),
        body: {'confirmLowStock': confirmLowStock},
      );

      if (response.isSuccess && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        final data = response.data as Map<String, dynamic>;
        return OrderDto.fromJson(data['data'] ?? data);
      } else {
        throw Exception(response.message ?? 'Failed to complete order');
      }
    } catch (e) {
      debugPrint('OrderApiService.completeOrder error: $e');
      rethrow;
    }
  }

  /// Cancel an order
  ///
  /// API: POST /api/order/{id}/cancel
  /// Returns: bool (success/failure)
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.cancelOrder(orderId));

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to cancel order');
      }
    } catch (e) {
      debugPrint('OrderApiService.cancelOrder error: $e');
      rethrow;
    }
  }
}
