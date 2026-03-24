import 'package:flutter/foundation.dart';
import '../../../core/network/api_error_message_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/order_dto.dart';

class OrderConfirmationRequiredException implements Exception {
  final List<String> warnings;
  final bool requiresLowStockConfirmation;
  final bool requiresCreditLimitConfirmation;

  const OrderConfirmationRequiredException({
    required this.warnings,
    required this.requiresLowStockConfirmation,
    required this.requiresCreditLimitConfirmation,
  });

  @override
  String toString() {
    if (warnings.isNotEmpty) {
      return warnings.join('\n');
    }
    return 'Confirmation is required before continuing.';
  }
}

/// Order API Service - Handles direct API communication for orders
///
/// Responsibilities:
/// 1. Make HTTP requests via ApiClient
/// 2. Parse raw responses to DTOs
/// 3. Handle API-specific errors
/// 4. Return DTOs to Repository
class OrderApiService {
  final ApiClient _apiClient;
  static const String _genericError = ApiErrorMessageParser.genericMessage;

  OrderApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Map<String, dynamic> _extractOrderPayload(Map<String, dynamic> responseData) {
    final dynamic dataNode = responseData['data'];
    if (dataNode is Map<String, dynamic>) {
      final dynamic orderNode = dataNode['order'];
      if (orderNode is Map<String, dynamic>) {
        return orderNode;
      }
      return dataNode;
    }
    return responseData;
  }

  void _throwIfConfirmationRequired(Map<String, dynamic> responseData) {
    final dynamic dataNode = responseData['data'];
    if (dataNode is! Map<String, dynamic>) return;

    final requiresConfirmation = dataNode['requiresConfirmation'] == true;
    if (!requiresConfirmation) return;

    final warnings = <String>[];
    final warningNode = dataNode['warnings'];
    if (warningNode is List) {
      for (final item in warningNode) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) warnings.add(text);
      }
    }

    final joinedWarnings = warnings.join(' ').toUpperCase();
    final requiresLowStock = joinedWarnings.contains('LOW_STOCK_CONFIRM_REQUIRED');
    final requiresCreditLimit =
        joinedWarnings.contains('DEBTOR_CREDIT_LIMIT_EXCEEDED_CONFIRM_REQUIRED');

    throw OrderConfirmationRequiredException(
      warnings: warnings,
      requiresLowStockConfirmation: requiresLowStock,
      requiresCreditLimitConfirmation: requiresCreditLimit,
    );
  }

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
        if (locationId != null && locationId.trim().isNotEmpty)
          'BusinessLocationId': locationId,
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
        throw Exception(response.message ?? _genericError);
      }
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      debugPrint('OrderApiService.getOrders error: $e');
      throw Exception(ApiErrorMessageParser.parse(e));
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
          throw Exception(_genericError);
        }

        final data = response.data as Map<String, dynamic>;
        return OrderDto.fromJson(_extractOrderPayload(data));
      } else {
        throw Exception(response.message ?? _genericError);
      }
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      debugPrint('OrderApiService.getOrder error: $e');
      throw Exception(ApiErrorMessageParser.parse(e));
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
          throw Exception(_genericError);
        }

        final data = response.data as Map<String, dynamic>;
        _throwIfConfirmationRequired(data);
        return OrderDto.fromJson(_extractOrderPayload(data));
      } else {
        throw Exception(response.message ?? _genericError);
      }
    } on OrderConfirmationRequiredException {
      rethrow;
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      debugPrint('OrderApiService.createOrder error: $e');
      throw Exception(ApiErrorMessageParser.parse(e));
    }
  }

  /// Update an existing order (pending)
  ///
  /// API: PUT /api/my-business/accounting/orders/{id}
  /// Returns: OrderDto
  Future<OrderDto> updateOrder({
    required String orderId,
    required Map<String, dynamic> body,
    String? idempotencyKey,
  }) async {
    try {
      final updatedBody = <String, dynamic>{...body};
      if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
        updatedBody['idempotencyKey'] = idempotencyKey.trim();
      }

      final response = await _apiClient.put(
        ApiEndpoints.updateOrder(orderId),
        body: updatedBody,
        headers: {
          if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
            'Idempotency-Key': idempotencyKey.trim(),
        },
      );

      if (response.isSuccess && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception(_genericError);
        }

        final data = response.data as Map<String, dynamic>;
        _throwIfConfirmationRequired(data);
        return OrderDto.fromJson(_extractOrderPayload(data));
      } else {
        throw Exception(response.message ?? _genericError);
      }
    } on OrderConfirmationRequiredException {
      rethrow;
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      debugPrint('OrderApiService.updateOrder error: $e');
      throw Exception(ApiErrorMessageParser.parse(e));
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
          throw Exception(_genericError);
        }

        final data = response.data as Map<String, dynamic>;
        _throwIfConfirmationRequired(data);
        return OrderDto.fromJson(_extractOrderPayload(data));
      } else {
        throw Exception(response.message ?? _genericError);
      }
    } on OrderConfirmationRequiredException {
      rethrow;
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      debugPrint('OrderApiService.completeOrder error: $e');
      throw Exception(ApiErrorMessageParser.parse(e));
    }
  }

  /// Cancel an order
  ///
  /// API: POST /api/order/{id}/cancel
  /// Returns: bool (success/failure)
  Future<bool> cancelOrder(String orderId, {required String cancelReason}) async {
    try {
      final normalizedReason = cancelReason.trim();
      if (normalizedReason.isEmpty) {
        throw Exception('Cancel reason is required');
      }

      final response = await _apiClient.post(
        ApiEndpoints.cancelOrder(orderId),
        body: {'cancelReason': normalizedReason},
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.message ?? _genericError);
      }
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      debugPrint('OrderApiService.cancelOrder error: $e');
      throw Exception(ApiErrorMessageParser.parse(e));
    }
  }
}
