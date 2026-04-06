import 'auth_api_service.dart';
import 'models/auth_response.dart';
import 'models/credentials_response.dart';
import 'models/user_profile_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

abstract class AuthRepository {
  Future<AuthResponse> loginWithPhone({
    required String phone,
    required String password,
  });

  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> loginWithGoogle();

  Future<AuthResponse> loginWithGoogleToken(String idToken);

  Future<AuthResponse> registerWithPhone({
    required String phone,
    required String password,
    required String firebaseIdToken,
    String? fullName,
  });

  Future<AuthResponse> setPassword({required String password});

  Future<CredentialsResponse> getCredentials();

  Future<AuthResponse> linkEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> linkGoogle({required String idToken});

  Future<AuthResponse> linkPhone({
    required String phone,
    required String firebaseIdToken,
    String? password,
  });

  Future<AuthResponse> refreshToken();

  Future<AuthResponse> forgotPasswordSendOtp({required String email});

  Future<AuthResponse> forgotPasswordVerifyOtp({
    required String email,
    required String otpCode,
  });

  Future<AuthResponse> forgotPasswordReset({required String password});

  Future<UserProfileResponse> getProfile();

  Future<UserProfileResponse> updateProfile({
    String? fullName,
    String? taxCode,
  });

  Future<UserProfileResponse> updateAvatar({required String avatarPath});

  Future<UserProfileResponse> removeAvatar();

  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AuthResponse> deleteAccount({required String password});

  Future<void> logout();

  Future<bool> isLoggedIn();

  Future<String?> getStoredAccessToken();

  // Legacy stubs
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

  Future<AuthResponse> resendOtp({required String phone});
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _apiService;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl(this._apiService, this._secureStorage);

  @override
  Future<AuthResponse> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiService.loginWithPhone(
        phone: phone,
        password: password,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.loginWithEmail(
        email: email,
        password: password,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> loginWithGoogle() async {
    try {
      // Google Sign-In is handled in AuthBloc; this method receives the idToken
      // from the caller after Google Sign-In completes
      throw UnimplementedError('Call loginWithGoogleToken(idToken) instead');
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> registerWithPhone({
    required String phone,
    required String password,
    required String firebaseIdToken,
    String? fullName,
  }) async {
    try {
      final response = await _apiService.registerWithPhone(
        phone: phone,
        password: password,
        firebaseIdToken: firebaseIdToken,
        fullName: fullName,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> loginWithGoogleToken(String idToken) async {
    try {
      final response = await _apiService.loginWithGoogle(idToken: idToken);
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> setPassword({required String password}) async {
    try {
      final response = await _apiService.setPassword(password: password);
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<CredentialsResponse> getCredentials() async {
    try {
      final response = await _apiService.getCredentials();
      return CredentialsResponse.fromJson(response);
    } catch (e) {
      return CredentialsResponse(
        success: false,
        message: e is ApiException ? e.message : e.toString().replaceAll('Exception: ', ''),
        credentialTypes: const [],
      );
    }
  }

  @override
  Future<AuthResponse> linkEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.linkEmail(
        email: email,
        password: password,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> linkGoogle({required String idToken}) async {
    try {
      final response = await _apiService.linkGoogle(idToken: idToken);
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> linkPhone({
    required String phone,
    required String firebaseIdToken,
    String? password,
  }) async {
    try {
      final response = await _apiService.linkPhone(
        phone: phone,
        firebaseIdToken: firebaseIdToken,
        password: password,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken() async {
    try {
      final storedRefreshToken = await _secureStorage.getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return AuthResponse(success: false, message: 'No refresh token stored');
      }
      final response = await _apiService.refreshToken(
        refreshToken: storedRefreshToken,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> forgotPasswordSendOtp({required String email}) async {
    try {
      final response = await _apiService.forgotPasswordSendOtp(email: email);
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> forgotPasswordVerifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await _apiService.forgotPasswordVerifyOtp(
        email: email,
        otpCode: otpCode,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> forgotPasswordReset({required String password}) async {
    try {
      final response = await _apiService.forgotPasswordReset(
        password: password,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<UserProfileResponse> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      return UserProfileResponse(
        success: false,
        message: e is ApiException ? e.message : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<UserProfileResponse> updateProfile({
    String? fullName,
    String? taxCode,
  }) async {
    try {
      final response = await _apiService.updateProfile(
        fullName: fullName,
        taxCode: taxCode,
      );
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      return UserProfileResponse(
        success: false,
        message: e is ApiException ? e.message : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<UserProfileResponse> updateAvatar({required String avatarPath}) async {
    try {
      final response = await _apiService.updateAvatar(avatarPath: avatarPath);
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      return UserProfileResponse(
        success: false,
        message: e is ApiException ? e.message : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<UserProfileResponse> removeAvatar() async {
    try {
      final response = await _apiService.removeAvatar();
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      return UserProfileResponse(
        success: false,
        message: e is ApiException ? e.message : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<AuthResponse> deleteAccount({required String password}) async {
    try {
      final response = await _apiService.deleteAccount(password: password);
      return AuthResponse.fromJson(response);
    } catch (e) {
      return _errorResponse(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final storedRefreshToken = await _secureStorage.getRefreshToken();
      if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
        await _apiService.logout(refreshToken: storedRefreshToken);
      }
    } catch (_) {
      // Always clear local tokens, even if API call fails
    } finally {
      await _secureStorage.clearAuthTokens();
    }
  }

  @override
  Future<bool> isLoggedIn() => _secureStorage.hasAccessToken();

  @override
  Future<String?> getStoredAccessToken() => _secureStorage.getAccessToken();

  @override
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    return AuthResponse(
      success: false,
      message: 'Registration not supported via this endpoint',
    );
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    // OTP registration not yet supported by backend
    return AuthResponse(
      success: false,
      message: 'OTP registration not yet supported',
    );
  }

  @override
  Future<AuthResponse> resendOtp({required String phone}) async {
    return AuthResponse(
      success: false,
      message: 'OTP registration not yet supported',
    );
  }

  AuthResponse _errorResponse(Object e) {
    if (e is ApiException) return AuthResponse(success: false, message: e.message);
    return AuthResponse(success: false, message: e.toString().replaceAll('Exception: ', ''));
  }
}
