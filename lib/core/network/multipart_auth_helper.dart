import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_config.dart';
import '../database/database_manager.dart';
import '../routing/app_router.dart';
import '../storage/secure_storage.dart';
import '../../shared/cache/cache_manager.dart';
import '../../shared/context/business_context.dart';
import '../../shared/context/user_profile_context.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class MultipartAuthHelper {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  MultipartAuthHelper({
    required ApiClient apiClient,
    SecureStorage? secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage ?? SecureStorage();

  Future<Response<dynamic>> executeWithRefresh({
    required Future<Response<dynamic>> Function(Dio dio) send,
  }) async {
    final initialToken = await _getAccessToken();
    final dio = _createMultipartDio(accessToken: initialToken);

    try {
      return await send(dio);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        rethrow;
      }

      String? refreshedToken;
      try {
        refreshedToken = await _refreshAccessToken();
      } catch (_) {
        refreshedToken = null;
      }
      if (refreshedToken == null || refreshedToken.isEmpty) {
        await _handleAuthExpired();
        rethrow;
      }

      final retryDio = _createMultipartDio(accessToken: refreshedToken);
      try {
        return await send(retryDio);
      } on DioException catch (retryError) {
        if (retryError.response?.statusCode == 401) {
          await _handleAuthExpired();
        }
        rethrow;
      }
    }
  }

  Future<String?> _getAccessToken() async {
    return _secureStorage.read(key: SecureStorageKeys.accessToken);
  }

  Future<String?> _getRefreshToken() async {
    return _secureStorage.read(key: SecureStorageKeys.refreshToken);
  }

  Dio _createMultipartDio({String? accessToken}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: _apiClient.baseUrl,
        connectTimeout: AppConfig.connectionTimeout,
        sendTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {
          'Accept': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };

    return dio;
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final dio = _createMultipartDio();
      final response = await dio.post(
        ApiEndpoints.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
        options: Options(contentType: Headers.jsonContentType),
      );

      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = payload['data'] is Map<String, dynamic>
          ? payload['data'] as Map<String, dynamic>
          : payload;

      final newAccessToken =
          data['token'] as String? ?? data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return null;
      }

      await _secureStorage.write(
        key: SecureStorageKeys.accessToken,
        value: newAccessToken,
      );

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: newRefreshToken,
        );
      }

      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleAuthExpired() async {
    await _secureStorage.clearAuthTokens();
    await _secureStorage.clearGoogleOnboardingStep();
    await _secureStorage.clearCredentialTypes();
    await BusinessContext().clear();
    await UserProfileContext().clear();
    await CacheManager().clearAll();
    await DatabaseManager().clearForLogout();
    AppRouter.globalAppBarState.reset();
    AppRouter.navigateAndClearStack(AppRoutes.login);
  }
}
