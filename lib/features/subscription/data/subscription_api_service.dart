import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/subscription_models.dart';

class SubscriptionApiService {
  final ApiClient _apiClient;

  SubscriptionApiService(this._apiClient);

  Future<List<SubscriptionPlanDto>> getSubscriptionPlans({CancelToken? cancelToken}) async {
    final response = await _apiClient.get(
      ApiEndpoints.subscriptionPlans,
    );

    // Assuming the API returns a standardized wrapper where `data` holds the actual payload.
    // E.g., { "data": [{...}], "success": true, ... }
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>;
    return data.map((json) => SubscriptionPlanDto.fromJson(json)).toList();
  }

  Future<CurrentSubscriptionDto?> getCurrentSubscription({
    CancelToken? cancelToken,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.currentSubscription,
    );

    final payload = response.data as Map<String, dynamic>;
    if (payload['data'] == null) {
      return null;
    }

    return CurrentSubscriptionDto.fromJson(payload['data']);
  }

  Future<CheckoutSessionResponseDto> checkoutSubscription(int planId, {String platform = 'mobile'}) async {
    final response = await _apiClient.post(
      ApiEndpoints.checkoutSubscription,
      body: {
        'subscriptionPlanId': planId,
        'quantity': 1,
        'platform': platform,
      },
    );

    final payload = response.data as Map<String, dynamic>;
    return CheckoutSessionResponseDto.fromJson(payload['data']);
  }

  Future<String> createFirebaseCustomToken() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.firebaseCustomToken,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Failed to create Firebase custom token',
      );
    }

    final payload = response.data!;
    final data = payload['data'] as Map<String, dynamic>? ?? const {};
    final customToken = data['customToken'] as String? ?? '';
    if (customToken.isEmpty) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Firebase custom token is missing in response',
      );
    }

    return customToken;
  }
}
