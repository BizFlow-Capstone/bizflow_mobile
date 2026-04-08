import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
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

      final refreshedToken = await _refreshAccessToken();
      if (refreshedToken == null || refreshedToken.isEmpty) {
        rethrow;
      }

      final retryDio = _createMultipartDio(accessToken: refreshedToken);
      return await send(retryDio);
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
  }
}
