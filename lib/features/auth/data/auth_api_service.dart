import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Auth API Service - Calls BizFlow auth endpoints
/// Uses the shared ApiClient (with interceptors) instead of raw Dio
class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Login with phone number + password
  /// Phone will be normalized to +84 format by server
  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.loginPhone,
      body: {
        'phone': phone,
        'password': password,
        'deviceInfo': _getDeviceInfo(),
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Login failed',
      );
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String password,
    required String firebaseIdToken,
    String? fullName,
    String? deviceInfo,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.registerPhone,
      body: {
        'phone': phone,
        'password': password,
        'firebaseIdToken': firebaseIdToken,
        if (fullName != null && fullName.trim().isNotEmpty)
          'fullName': fullName.trim(),
        'deviceInfo': deviceInfo ?? _getDeviceInfo(),
      },
      parser: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        if (data is List) {
          return <String, dynamic>{'success': true, 'data': data};
        }
        if (data is String) {
          return <String, dynamic>{
            'success': true,
            'message': data,
            'data': data,
          };
        }
        return <String, dynamic>{'success': true, 'data': data};
      },
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Phone registration failed',
      );
    }
    return response.data!;
  }

  /// Login with email + password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.loginEmail,
      body: {
        'email': email,
        'password': password,
        'deviceInfo': _getDeviceInfo(),
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Login failed',
      );
    }
    return response.data!;
  }

  /// Login or register with Google ID Token
  /// Returns isNewAccount=true if this is a new registration
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? deviceInfo,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.googleAuth,
      body: {'idToken': idToken, 'deviceInfo': deviceInfo ?? _getDeviceInfo()},
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Google login failed',
      );
    }
    return response.data!;
  }

  /// Set password after Google registration (for new accounts)
  /// Requires Bearer token already set in AuthInterceptor
  Future<Map<String, dynamic>> setPassword({required String password}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.setPassword,
      body: {'password': password},
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Set password failed',
      );
    }
    return response.data ?? {'success': true};
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    String? deviceInfo,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.refreshTokenEndpoint,
      body: {
        'refreshToken': refreshToken,
        'deviceInfo': deviceInfo ?? _getDeviceInfo(),
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Token refresh failed',
      );
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> getCredentials() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.credentials,
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Get credentials failed',
      );
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> linkEmail({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.linkEmail,
      body: {'email': email, 'password': password},
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Link email failed',
      );
    }
    return response.data ?? {'success': true, 'message': response.message};
  }

  Future<Map<String, dynamic>> linkGoogle({required String idToken}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.linkGoogle,
      body: {'idToken': idToken},
      parser: (data) => data as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Link Google failed',
      );
    }
    return response.data ?? {'success': true, 'message': response.message};
  }

  Future<Map<String, dynamic>> linkPhone({
    required String phone,
    required String firebaseIdToken,
    String? password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.linkPhone,
      body: {
        'phone': phone,
        'firebaseIdToken': firebaseIdToken,
        if (password != null && password.trim().isNotEmpty)
          'password': password.trim(),
      },
      parser: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        if (data is List) {
          return <String, dynamic>{'success': true, 'data': data};
        }
        if (data is String) {
          return <String, dynamic>{
            'success': true,
            'message': data,
            'data': data,
          };
        }
        return <String, dynamic>{'success': true, 'data': data};
      },
    );
    if (!response.isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.message ?? 'Link phone failed',
      );
    }
    return response.data ?? {'success': true, 'message': response.message};
  }

  /// Logout - revokes refresh token on server
  Future<void> logout({required String refreshToken}) async {
    await _apiClient.post<void>(
      ApiEndpoints.logoutEndpoint,
      body: {'refreshToken': refreshToken, 'deviceInfo': _getDeviceInfo()},
    );
  }

  String _getDeviceInfo() {
    try {
      return 'BizFlow Mobile / ${Platform.operatingSystem}';
    } catch (_) {
      return 'BizFlow Mobile';
    }
  }
}
