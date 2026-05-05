import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PushTokenApiService {
  final ApiClient _apiClient;

  PushTokenApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> registerToken(
    String token, {
    String? deviceName,
    required String platform,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerDeviceToken,
      body: {
        'token': token,
        'deviceName': deviceName,
        'platform': platform,
      },
    );

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Failed to register device token');
    }
  }

  Future<void> unregisterToken(String token) async {
    final response = await _apiClient.post(
      ApiEndpoints.unregisterDeviceToken,
      body: {'token': token},
    );

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Failed to unregister device token');
    }
  }
}
