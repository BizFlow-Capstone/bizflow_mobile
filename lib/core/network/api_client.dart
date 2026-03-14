import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HTTP Methods
enum HttpMethod { get, post, put, patch, delete }

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final int statusCode;
  final String? message;
  final bool isSuccess;

  ApiResponse({
    this.data,
    required this.statusCode,
    this.message,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data, {int statusCode = 200, String? message}) {
    return ApiResponse(
      data: data,
      statusCode: statusCode,
      message: message,
      isSuccess: true,
    );
  }

  factory ApiResponse.error({required int statusCode, String? message}) {
    return ApiResponse(
      statusCode: statusCode,
      message: message,
      isSuccess: false,
    );
  }
}

/// API Exception
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException({required this.statusCode, required this.message, this.data});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

/// Request Interceptor
abstract class RequestInterceptor {
  Future<Map<String, String>> onRequest(Map<String, String> headers);
}

/// Response Interceptor
abstract class ResponseInterceptor {
  Future<void> onResponse(int statusCode, dynamic body);
  Future<void> onError(ApiException error);
}

/// Auth Interceptor - Tự động thêm token
class AuthInterceptor implements RequestInterceptor {
  final Future<String?> Function() getToken;

  AuthInterceptor({required this.getToken});

  @override
  Future<Map<String, String>> onRequest(Map<String, String> headers) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}

/// Language Interceptor - Tự động thêm Accept-Language header
class LanguageInterceptor implements RequestInterceptor {
  final String Function() getCurrentLanguage;

  LanguageInterceptor({required this.getCurrentLanguage});

  @override
  Future<Map<String, String>> onRequest(Map<String, String> headers) async {
    final language = getCurrentLanguage();
    if (language.isNotEmpty) {
      headers['Accept-Language'] = language;
    }
    return headers;
  }
}

/// Logging Interceptor
class LoggingInterceptor implements ResponseInterceptor {
  @override
  Future<void> onResponse(int statusCode, dynamic body) async {
    debugPrint('API Response [$statusCode]: $body');
  }

  @override
  Future<void> onError(ApiException error) async {
    debugPrint('API Error [${error.statusCode}]: ${error.message}');
  }
}

/// Token Refresh Interceptor
/// Watches for 401 responses, tries to refresh the access token,
/// then retries the original request automatically.
/// On refresh failure, calls [onRefreshFailed] (e.g., to force logout).
class TokenRefreshInterceptor implements ResponseInterceptor {
  final Future<String?> Function() getRefreshToken;
  final Future<void> Function({
    required String accessToken,
    required String refreshToken,
  }) onTokenRefreshed;
  final Future<void> Function() onRefreshFailed;
  final String baseUrl;
  final String refreshEndpoint;
  final Duration timeout;
  final List<RequestInterceptor> requestInterceptors;

  bool _isRefreshing = false;

  TokenRefreshInterceptor({
    required this.getRefreshToken,
    required this.onTokenRefreshed,
    required this.onRefreshFailed,
    required this.baseUrl,
    required this.refreshEndpoint,
    required this.timeout,
    required this.requestInterceptors,
  });

  @override
  Future<void> onResponse(int statusCode, dynamic body) async {
    // nothing to do on success
  }

  @override
  Future<void> onError(ApiException error) async {
    // handled externally via shouldRefresh
  }

  /// Returns true if a 401 should trigger a refresh attempt
  bool shouldRefresh(int statusCode) => statusCode == 401 && !_isRefreshing;

  /// Attempt to refresh tokens. Returns the new access token on success, null on failure.
  Future<String?> attemptRefresh() async {
    if (_isRefreshing) return null;
    _isRefreshing = true;
    try {
      final storedRefreshToken = await getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        await onRefreshFailed();
        return null;
      }

      final client = HttpClient()
        ..connectionTimeout = timeout
        ..badCertificateCallback = (cert, host, port) {
          if (kDebugMode &&
              (host == 'localhost' ||
                  host == '10.0.2.2' ||
                  host.startsWith('192.168.'))) {
            return true;
          }
          return false;
        };

      try {
        final uri = Uri.parse('$baseUrl$refreshEndpoint');
        final request = await client.postUrl(uri);

        var headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        for (final interceptor in requestInterceptors) {
          headers = await interceptor.onRequest(headers);
        }
        headers.forEach((key, value) => request.headers.set(key, value));

        final body = json.encode({'refreshToken': storedRefreshToken});
        request.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
        request.write(body);

        final response = await request.close().timeout(timeout);
        final responseBody = await response.transform(utf8.decoder).join();
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonResponse['data'] as Map<String, dynamic>? ??
              jsonResponse;
          final newAccessToken =
              data['token'] as String? ?? data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;

          if (newAccessToken != null && newRefreshToken != null) {
            await onTokenRefreshed(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );
            return newAccessToken;
          }
        }

        await onRefreshFailed();
        return null;
      } finally {
        client.close();
      }
    } catch (_) {
      await onRefreshFailed();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}

/// HTTP Client
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final List<RequestInterceptor> requestInterceptors;
  final List<ResponseInterceptor> responseInterceptors;

  late final HttpClient _client;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.requestInterceptors = const [],
    this.responseInterceptors = const [],
  }) {
    _client = HttpClient()
      ..connectionTimeout = timeout
      //  DEVELOPMENT ONLY: Bypass SSL certificate validation
      //  NEVER use this in production!
      ..badCertificateCallback = (cert, host, port) {
        // Allow self-signed certificates in development
        if (kDebugMode &&
            (host == 'localhost' ||
                host == '10.0.2.2' ||
                host == '192.168.1.9' ||
                host == '192.168.1.197')) {
          return true;
        }
        return false;
      };
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _request<T>(
      HttpMethod.get,
      path,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _request<T>(
      HttpMethod.post,
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _request<T>(
      HttpMethod.put,
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _request<T>(
      HttpMethod.patch,
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _request<T>(
      HttpMethod.delete,
      path,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  /// Internal request method
  Future<ApiResponse<T>> _request<T>(
    HttpMethod method,
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) async {
    ApiResponse<T>? result;
    try {
      result = await _doRequest<T>(
        method,
        path,
        body: body,
        queryParams: queryParams,
        headers: headers,
        parser: parser,
      );
    } on ApiException catch (e) {
      // Check for 401 — attempt token refresh
      final refreshInterceptor = responseInterceptors
          .whereType<TokenRefreshInterceptor>()
          .firstOrNull;
      if (e.statusCode == 401 &&
          refreshInterceptor != null &&
          refreshInterceptor.shouldRefresh(e.statusCode)) {
        final newToken = await refreshInterceptor.attemptRefresh();
        if (newToken != null) {
          // Retry original request with new token
          return _doRequest<T>(
            method,
            path,
            body: body,
            queryParams: queryParams,
            headers: headers,
            parser: parser,
          );
        }
      }
      // No refresh possible — propagate
      rethrow;
    }
    return result;
  }

  /// Performs the actual HTTP request (no retry logic)
  Future<ApiResponse<T>> _doRequest<T>(
    HttpMethod method,
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) async {
    try {
      // Build URL
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('API Request: ${method.name.toUpperCase()} $uri');
      }

      // Create request
      final request = await _createRequest(method, uri);

      // Set headers
      var requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      // Apply request interceptors
      for (final interceptor in requestInterceptors) {
        requestHeaders = await interceptor.onRequest(requestHeaders);
      }

      requestHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Set body (set encoding to utf8 to support non-ASCII characters like Vietnamese)
      if (body != null) {
        final jsonBody = json.encode(body);
        request.headers.contentType = ContentType(
          'application',
          'json',
          charset: 'utf-8',
        );
        request.write(jsonBody);
      }

      // Send request
      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (kDebugMode) {
        debugPrint('API Raw Response: [${response.statusCode}] $uri');
      }

      // Handle redirects (307, 308, etc.)
      if ((response.statusCode == 307 || response.statusCode == 308) &&
          response.headers['location'] != null) {
        final redirectUrl = response.headers['location']!.first;
        debugPrint('Redirect detected: ${response.statusCode} -> $redirectUrl');

        // Create a new request to the redirect location
        final redirectUri = Uri.parse(redirectUrl);
        final redirectRequest = await _createRequest(method, redirectUri);

        // Reapply all headers to the redirect request
        requestHeaders.forEach((key, value) {
          redirectRequest.headers.set(key, value);
        });

        // Reapply body if needed (for PUT/POST redirects)
        if (body != null) {
          final jsonBody = json.encode(body);
          redirectRequest.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          redirectRequest.write(jsonBody);
        }

        // Send redirect request
        final redirectResponse = await redirectRequest.close().timeout(timeout);
        final redirectBody = await redirectResponse
            .transform(utf8.decoder)
            .join();

        // Parse redirect response
        dynamic jsonRedirectResponse;
        try {
          jsonRedirectResponse = json.decode(redirectBody);
        } catch (_) {
          jsonRedirectResponse = redirectBody;
        }

        // Apply response interceptors to redirect response
        for (final interceptor in responseInterceptors) {
          await interceptor.onResponse(
            redirectResponse.statusCode,
            jsonRedirectResponse,
          );
        }

        // Check redirect response status
        if (redirectResponse.statusCode >= 200 &&
            redirectResponse.statusCode < 300) {
          final data = parser != null
              ? parser(jsonRedirectResponse)
              : jsonRedirectResponse as T?;
          return ApiResponse.success(
            data as T,
            statusCode: redirectResponse.statusCode,
          );
        } else {
          final error = ApiException(
            statusCode: redirectResponse.statusCode,
            message: _getErrorMessage(
              redirectResponse.statusCode,
              jsonRedirectResponse,
            ),
            data: jsonRedirectResponse,
          );

          for (final interceptor in responseInterceptors) {
            await interceptor.onError(error);
          }

          throw error;
        }
      }

      // Parse response
      dynamic jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
      } catch (_) {
        jsonResponse = responseBody;
      }

      // Apply response interceptors
      for (final interceptor in responseInterceptors) {
        await interceptor.onResponse(response.statusCode, jsonResponse);
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = parser != null ? parser(jsonResponse) : jsonResponse as T?;
        return ApiResponse.success(data as T, statusCode: response.statusCode);
      } else {
        final error = ApiException(
          statusCode: response.statusCode,
          message: _getErrorMessage(response.statusCode, jsonResponse),
          data: jsonResponse,
        );

        for (final interceptor in responseInterceptors) {
          await interceptor.onError(error);
        }

        throw error;
      }
    } on SocketException {
      throw ApiException(statusCode: -1, message: 'No internet connection');
    } on TimeoutException {
      throw ApiException(statusCode: -2, message: 'Request timeout');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: -3, message: e.toString());
    }
  }

  Future<HttpClientRequest> _createRequest(HttpMethod method, Uri uri) {
    switch (method) {
      case HttpMethod.get:
        return _client.getUrl(uri);
      case HttpMethod.post:
        return _client.postUrl(uri);
      case HttpMethod.put:
        return _client.putUrl(uri);
      case HttpMethod.patch:
        return _client.patchUrl(uri);
      case HttpMethod.delete:
        return _client.deleteUrl(uri);
    }
  }

  String _getErrorMessage(int statusCode, dynamic body) {
    if (body is Map && body.containsKey('message')) {
      return body['message'].toString();
    }

    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      default:
        return 'Unknown error';
    }
  }

  /// Close client
  void close() {
    _client.close();
  }
}
