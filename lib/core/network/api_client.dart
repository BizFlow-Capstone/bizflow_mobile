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
                  host.startsWith('192.168.') ||
                  host.startsWith('172.20.10.'))) {
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

  static const Set<String> _nonRefreshable401MessageCodes = {
    'AUTH_CURRENT_PASSWORD_INCORRECT',
  };

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
                host.startsWith('192.168.') ||
                host.startsWith('172.20.10.'))) {
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

  /// POST Multipart request (supports files)
  Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    required Map<String, String> fields,
    Map<String, File>? files,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) async {
    const boundary = '----BizFlowBoundary';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final request = await _client.postUrl(uri);
      
      var requestHeaders = <String, String>{
        'Content-Type': 'multipart/form-data; boundary=$boundary',
        'Accept': 'application/json',
        ...?headers,
      };

      for (final interceptor in requestInterceptors) {
        requestHeaders = await interceptor.onRequest(requestHeaders);
      }
      requestHeaders.forEach((key, value) => request.headers.set(key, value));

      // Build body
      final sink = request;
      
      // Fields
      fields.forEach((key, value) {
        sink.write('--$boundary\r\n');
        sink.write('Content-Disposition: form-data; name="$key"\r\n\r\n');
        sink.write('$value\r\n');
      });

      // Files
      if (files != null) {
        for (final entry in files.entries) {
          final file = entry.value;
          final filename = file.path.split(Platform.pathSeparator).last;
          sink.write('--$boundary\r\n');
          sink.write(
            'Content-Disposition: form-data; name="${entry.key}"; filename="$filename"\r\n',
          );
          sink.write('Content-Type: application/octet-stream\r\n\r\n');
          await sink.addStream(file.openRead());
          sink.write('\r\n');
        }
      }

      sink.write('--$boundary--\r\n');

      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      dynamic jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
      } catch (_) {
        jsonResponse = responseBody;
      }

      for (final interceptor in responseInterceptors) {
        await interceptor.onResponse(response.statusCode, jsonResponse);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = parser != null ? parser(jsonResponse) : jsonResponse as T?;
        return ApiResponse.success(data as T, statusCode: response.statusCode);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: _getErrorMessage(response.statusCode, jsonResponse),
          data: jsonResponse,
        );
      }
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: -3, message: e.toString());
    }
  }

  /// PUT Multipart request (supports files)
  Future<ApiResponse<T>> putMultipart<T>(
    String path, {
    required Map<String, String> fields,
    Map<String, File>? files,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) async {
    const boundary = '----BizFlowBoundary';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final request = await _client.putUrl(uri);
      
      var requestHeaders = <String, String>{
        'Content-Type': 'multipart/form-data; boundary=$boundary',
        'Accept': 'application/json',
        ...?headers,
      };

      for (final interceptor in requestInterceptors) {
        requestHeaders = await interceptor.onRequest(requestHeaders);
      }
      requestHeaders.forEach((key, value) => request.headers.set(key, value));

      // Build body
      final sink = request;
      
      // Fields
      fields.forEach((key, value) {
        sink.write('--$boundary\r\n');
        sink.write('Content-Disposition: form-data; name="$key"\r\n\r\n');
        sink.write('$value\r\n');
      });

      // Files
      if (files != null) {
        for (final entry in files.entries) {
          final file = entry.value;
          final filename = file.path.split(Platform.pathSeparator).last;
          sink.write('--$boundary\r\n');
          sink.write(
            'Content-Disposition: form-data; name="${entry.key}"; filename="$filename"\r\n',
          );
          sink.write('Content-Type: application/octet-stream\r\n\r\n');
          await sink.addStream(file.openRead());
          sink.write('\r\n');
        }
      }

      sink.write('--$boundary--\r\n');

      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      dynamic jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
      } catch (_) {
        jsonResponse = responseBody;
      }

      for (final interceptor in responseInterceptors) {
        await interceptor.onResponse(response.statusCode, jsonResponse);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = parser != null ? parser(jsonResponse) : jsonResponse as T?;
        return ApiResponse.success(data as T, statusCode: response.statusCode);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: _getErrorMessage(response.statusCode, jsonResponse),
          data: jsonResponse,
        );
      }
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: -3, message: e.toString());
    }
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
          !_shouldSkipRefreshFor401(e) &&
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
        // Build query string manually to support multi-value params (List).
        // e.g. BusinessLocationIds=[5,6] → ?BusinessLocationIds=5&BusinessLocationIds=6
        final parts = <String>[];
        for (final entry in queryParams.entries) {
          final value = entry.value;
          if (value is List) {
            for (final item in value) {
              parts.add(
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(item.toString())}',
              );
            }
          } else {
            parts.add(
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value.toString())}',
            );
          }
        }
        uri = uri.replace(query: parts.join('&'));
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
      throw ApiException(statusCode: -1, message: 'Không có kết nối mạng, vui lòng kiểm tra lại');
    } on TimeoutException {
      throw ApiException(statusCode: -2, message: 'Kết nối máy chủ bị gián đoạn (Timeout)');
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

  bool _shouldSkipRefreshFor401(ApiException error) {
    final data = error.data;
    if (data is Map) {
      final rawCode = data['messageCode'];
      final messageCode = rawCode?.toString().trim();
      if (messageCode != null &&
          _nonRefreshable401MessageCodes.contains(messageCode)) {
        return true;
      }
    }
    return false;
  }

  String _getErrorMessage(int statusCode, dynamic body) {
    if (body is Map && body.containsKey('message')) {
      return body['message'].toString();
    }

    switch (statusCode) {
      case 400:
        return 'Yeu cau khong hop le';
      case 401:
        return 'Ban chua dang nhap';
      case 403:
        return 'Ban khong co quyen truy cap';
      case 404:
        return 'Khong tim thay du lieu';
      case 500:
        return 'Loi he thong, vui long thu lai sau';
      default:
        return 'Da xay ra loi khong xac dinh';
    }
  }

  /// Close client
  void close() {
    _client.close();
  }
}
