import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/context/user_profile_context.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/routing/app_router.dart';
import '../../../location/data/location_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';

/// Error codes for auth operations
/// These codes are mapped to localization keys in UI layer
enum AuthErrorCode {
  signupFailed,
  loginFailed,
  invalidCredentials,
  emailNotRegistered,
  accountNotVerified,
  otpFailed,
  invalidOtp,
  otpExpired,
  networkError,
  serverError,
  unknownError,
}

/// Auth BLoC - State Management for Authentication
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocationRepository locationRepository;
  final AuthRepository authRepository;
  final SecureStorage secureStorage;

  static const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && _clientId.isNotEmpty ? _clientId : null,
    serverClientId: !kIsWeb && _clientId.isNotEmpty ? _clientId : null,
    scopes: ['email', 'profile'],
  );

  AuthBloc({
    required this.locationRepository,
    required this.authRepository,
    required this.secureStorage,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignupRequested>(_onSignupRequested);
    on<GoogleSignupRequested>(_onGoogleSignupRequested);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<SetPasswordRequested>(_onSetPasswordRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ClearAuthError>(_onClearAuthError);
  }

  Future<void> _prefetchLocations() async {
    try {
      final locations = await locationRepository.getMyOwnedLocations();
      await CacheManager().set('my_owned_locations', {
        'data': locations.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Prefetch locations error: $e');
    }
  }

  /// Check stored token on app startup → route to home or login
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthCheckingStatus());
    try {
      final loggedIn = await authRepository.isLoggedIn();
      if (loggedIn) {
        final token = await authRepository.getStoredAccessToken();
        emit(AuthAuthenticated(accessToken: token ?? ''));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  /// Handle email/phone login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginInProgress());
    try {
      final AuthResponse result;
      if (event.email.isNotEmpty) {
        result = await authRepository.loginWithEmail(
          email: event.email,
          password: event.password,
        );
      } else {
        result = await authRepository.loginWithPhone(
          phone: event.phone,
          password: event.password,
        );
      }

      if (!result.success || result.accessToken == null) {
        emit(LoginFailure(
          errorCode: AuthErrorCode.loginFailed,
          serverMessage: result.message,
        ));
        return;
      }

      await secureStorage.saveAuthTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? '',
      );
      await UserProfileContext().saveProfile(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
      );
      AppRouter.globalAppBarState.updateProfile(
        name: result.fullName,
        avatarUrl: result.avatarUrl,
      );
      await _prefetchLocations();
      emit(LoginSuccess(
        accessToken: result.accessToken!,
        user: {
          if (result.fullName != null) 'fullName': result.fullName,
          if (result.avatarUrl != null) 'avatarUrl': result.avatarUrl,
        },
      ));
    } catch (e) {
      emit(LoginFailure(
        errorCode: AuthErrorCode.loginFailed,
        serverMessage: e.toString(),
      ));
    }
  }

  /// Handle Google Sign-In
  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginInProgress());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled sign-in
        emit(AuthInitial());
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        emit(const LoginFailure(errorCode: AuthErrorCode.loginFailed));
        return;
      }

      if (kDebugMode) {
        debugPrint('Google login API baseUrl: ${AppConfig.baseUrl}');
        debugPrint('Google token metadata: ${_extractTokenMetadata(idToken)}');
      }

      final result = await authRepository.loginWithGoogleToken(idToken);
      if (!result.success || result.accessToken == null) {
        emit(LoginFailure(
          errorCode: AuthErrorCode.loginFailed,
          serverMessage: result.message,
        ));
        return;
      }

      await secureStorage.saveAuthTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? '',
      );

      await UserProfileContext().saveProfile(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
      );
      AppRouter.globalAppBarState.updateProfile(
        name: result.fullName,
        avatarUrl: result.avatarUrl,
      );

      if (result.isNewAccount == true) {
        // New account — must set password before accessing the app
        emit(GoogleLoginSetPasswordRequired(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken ?? '',
        ));
      } else {
        await _prefetchLocations();
        emit(LoginSuccess(
          accessToken: result.accessToken!,
          user: const {},
        ));
      }
    } catch (e) {
      emit(LoginFailure(
        errorCode: AuthErrorCode.loginFailed,
        serverMessage: e.toString(),
      ));
    }
  }

  /// Set password for new Google accounts
  Future<void> _onSetPasswordRequested(
    SetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SetPasswordInProgress());
    try {
      final result = await authRepository.setPassword(
        password: event.password,
      );
      if (result.success) {
        await _prefetchLocations();
        emit(const SetPasswordSuccess());
      } else {
        emit(SetPasswordFailure(message: result.message));
      }
    } catch (e) {
      emit(SetPasswordFailure(message: e.toString()));
    }
  }

  /// Handle Signup (stub — no backend endpoint)
  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupInProgress());
    emit(const SignupFailure(errorCode: AuthErrorCode.signupFailed));
  }

  /// Handle Google Signup (routes through Google Login)
  Future<void> _onGoogleSignupRequested(
    GoogleSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    add(const GoogleLoginRequested());
  }

  /// OTP — not supported by backend
  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const OtpVerificationFailure(errorCode: AuthErrorCode.otpFailed));
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    // No-op
  }

  /// Handle Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LogoutInProgress());
    try {
      await authRepository.logout();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Logout error (ignored): $e');
    }
    await BusinessContext().clear();
    await UserProfileContext().clear();
    await CacheManager().clearAll();
    AppRouter.globalAppBarState.reset();
    emit(LogoutSuccess());
  }

  /// Handle Clear Error
  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  String _extractTokenMetadata(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return 'invalid_format';
      }

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final padding = payload.length % 4;
      if (padding > 0) {
        payload = payload.padRight(payload.length + (4 - padding), '=');
      }

      final payloadJson = utf8.decode(base64.decode(payload));
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;

      return jsonEncode({
        'aud': payloadMap['aud'],
        'azp': payloadMap['azp'],
        'iss': payloadMap['iss'],
        'sub': payloadMap['sub'],
      });
    } catch (_) {
      return 'unparsable';
    }
  }
}
