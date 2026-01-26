import 'auth_api_service.dart';
import 'models/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otpCode,
  });

  Future<AuthResponse> resendOtp({
    required String phone,
  });

  Future<AuthResponse> googleRegister({
    required String idToken,
    required String email,
    required String name,
  });
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    try {
      final response = await _apiService.verifyOtp(
        phone: phone,
        otpCode: otpCode,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<AuthResponse> resendOtp({
    required String phone,
  }) async {
    try {
      final response = await _apiService.resendOtp(phone: phone);
      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<AuthResponse> googleRegister({
    required String idToken,
    required String email,
    required String name,
  }) async {
    try {
      final response = await _apiService.googleRegister(
        idToken: idToken,
        email: email,
        name: name,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
