import 'package:dio/dio.dart';

class AuthApiService {
  final Dio _dio;

  // API Endpoints
  static const String _baseUrl = 'https://api.bizflow.com/api';
  static const String _registerEndpoint = '$_baseUrl/auth/register';
  static const String _verifyOtpEndpoint = '$_baseUrl/auth/verify-otp';
  static const String _resendOtpEndpoint = '$_baseUrl/auth/resend-otp';
  static const String _googleRegisterEndpoint = '$_baseUrl/auth/google-register';

  AuthApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                contentType: 'application/json',
              ),
            );

  /// Register new user
  /// Returns phone number for OTP verification
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        _registerEndpoint,
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw _handleError(response.statusCode, response.data);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verify OTP code
  /// Returns token and refresh token on success
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        _verifyOtpEndpoint,
        data: {
          'phone': phone,
          'otpCode': otpCode,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw _handleError(response.statusCode, response.data);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Resend OTP code
  Future<Map<String, dynamic>> resendOtp({
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        _resendOtpEndpoint,
        data: {
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw _handleError(response.statusCode, response.data);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Register with Google account
  Future<Map<String, dynamic>> googleRegister({
    required String idToken,
    required String email,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        _googleRegisterEndpoint,
        data: {
          'idToken': idToken,
          'email': email,
          'name': name,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw _handleError(response.statusCode, response.data);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle DIO errors
  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      return _handleError(
        error.response?.statusCode ?? 500,
        error.response?.data,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Kết nối timeout');
      case DioExceptionType.receiveTimeout:
        return Exception('Nhận dữ liệu timeout');
      case DioExceptionType.sendTimeout:
        return Exception('Gửi dữ liệu timeout');
      case DioExceptionType.badResponse:
        return Exception('Lỗi máy chủ');
      case DioExceptionType.badCertificate:
        return Exception('Lỗi chứng chỉ');
      case DioExceptionType.connectionError:
        return Exception('Không có kết nối mạng');
      case DioExceptionType.unknown:
        return Exception('Lỗi không xác định: ${error.message}');
      case DioExceptionType.cancel:
        return Exception('Yêu cầu bị hủy');
    }
  }

  /// Handle HTTP errors
  Exception _handleError(int? statusCode, dynamic responseData) {
    String message = 'Có lỗi xảy ra';

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? message;
    }

    switch (statusCode) {
      case 400:
        return Exception('Dữ liệu không hợp lệ: $message');
      case 401:
        return Exception('Xác thực thất bại: $message');
      case 409:
        return Exception('Email đã tồn tại');
      case 429:
        return Exception('Quá nhiều yêu cầu. Vui lòng thử lại sau');
      case 500:
        return Exception('Lỗi máy chủ. Vui lòng thử lại');
      case 503:
        return Exception('Máy chủ không khả dụng');
      default:
        return Exception(message);
    }
  }
}
