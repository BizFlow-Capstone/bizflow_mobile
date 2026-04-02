import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../../../core/services/firebase_messaging_service.dart';
import '../../../../core/database/database_manager.dart';
import '../../../location/data/location_repository.dart';
import '../../data/auth_repository.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/credentials_response.dart';

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
  final FirebaseMessagingService firebaseMessagingService;

  static const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && _clientId.isNotEmpty ? _clientId : null,
    serverClientId: !kIsWeb && _clientId.isNotEmpty ? _clientId : null,
    scopes: ['email', 'profile'],
  );
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _pendingPhoneNumber;
  String? _pendingPassword;
  String? _pendingFullName;
  String? _pendingVerificationId;

  String? _pendingLinkPhoneNumber;
  String? _pendingLinkPhonePassword;
  String? _pendingLinkPhoneVerificationId;

  AuthBloc({
    required this.locationRepository,
    required this.authRepository,
    required this.secureStorage,
    required this.firebaseMessagingService,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignupRequested>(_onSignupRequested);
    on<GoogleSignupRequested>(_onGoogleSignupRequested);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<SetPasswordRequested>(_onSetPasswordRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<RegisterWithPhoneRequested>(_onRegisterWithPhoneRequested);
    on<PhoneOtpCodeSubmitted>(_onPhoneOtpCodeSubmitted);
    on<ResendPhoneOtpRequested>(_onResendPhoneOtpRequested);
    on<LoadCredentialsRequested>(_onLoadCredentialsRequested);
    on<LinkEmailRequested>(_onLinkEmailRequested);
    on<LinkGoogleRequested>(_onLinkGoogleRequested);
    on<StartLinkPhoneRequested>(_onStartLinkPhoneRequested);
    on<SubmitLinkPhoneOtpRequested>(_onSubmitLinkPhoneOtpRequested);
    on<ResendLinkPhoneOtpRequested>(_onResendLinkPhoneOtpRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ClearAuthError>(_onClearAuthError);
  }

  /// Check stored token on app startup → route to home or login
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthCheckingStatus());
    try {
      final loggedIn = await authRepository.isLoggedIn();
      if (loggedIn) {
        await DatabaseManager().initialize();
        final needsSetPassword = await secureStorage.getNeedsSetPassword();
        if (needsSetPassword) {
          emit(const NeedsSetPasswordOnResume());
          return;
        }
        try {
          await firebaseMessagingService
              .registerCurrentToken()
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('AuthBloc: Token registration timed out or failed, proceeding...');
        }
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
        emit(
          LoginFailure(
            errorCode: AuthErrorCode.loginFailed,
            serverMessage: result.message,
          ),
        );
        return;
      }

      await secureStorage.saveAuthTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? '',
      );
      await UserProfileContext().saveProfile(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
        email: event.email,
        phone: result.phone ?? event.phone,
      );
      await DatabaseManager().initialize();
      await secureStorage.setNeedsSetPassword(false);
      AppRouter.globalAppBarState.updateProfile(
        name: result.fullName,
        avatarUrl: result.avatarUrl,
      );
      await firebaseMessagingService.registerCurrentToken();
      emit(
        LoginSuccess(
          accessToken: result.accessToken!,
          user: {
            if (result.fullName != null) 'fullName': result.fullName,
            if (result.avatarUrl != null) 'avatarUrl': result.avatarUrl,
          },
        ),
      );
    } catch (e) {
      emit(
        LoginFailure(
          errorCode: AuthErrorCode.loginFailed,
          serverMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  /// Handle Google Sign-In
  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginInProgress());
    try {
      await _resetGoogleSessionForAccountPicker();
      final googleUser = await _signInWithTimeout();
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
        emit(
          LoginFailure(
            errorCode: AuthErrorCode.loginFailed,
            serverMessage: result.message,
          ),
        );
        return;
      }

      await secureStorage.saveAuthTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? '',
      );

      await UserProfileContext().saveProfile(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
        email: googleUser.email,
        phone: result.phone,
      );
      await DatabaseManager().initialize();
      AppRouter.globalAppBarState.updateProfile(
        name: result.fullName,
        avatarUrl: result.avatarUrl,
      );

      if (result.isNewAccount == true) {
        await secureStorage.setNeedsSetPassword(true);
        // New account — must set password before accessing the app
        emit(
          GoogleLoginSetPasswordRequired(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken ?? '',
          ),
        );
      } else {
        await secureStorage.setNeedsSetPassword(false);
        await firebaseMessagingService.registerCurrentToken();
        emit(LoginSuccess(accessToken: result.accessToken!, user: const {}));
      }
    } catch (e) {
      emit(
        LoginFailure(
          errorCode: AuthErrorCode.loginFailed,
          serverMessage: _mapGoogleSignInError(e),
        ),
      );
    }
  }

  /// Set password for new Google accounts
  Future<void> _onSetPasswordRequested(
    SetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SetPasswordInProgress());
    try {
      final result = await authRepository.setPassword(password: event.password);
      if (result.success) {
        await secureStorage.setNeedsSetPassword(false);
        await firebaseMessagingService.registerCurrentToken();
        emit(const SetPasswordSuccess());
      } else {
        emit(SetPasswordFailure(message: result.message));
      }
    } catch (e) {
      emit(SetPasswordFailure(message: ApiErrorMessageParser.parse(e)));
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

  Future<void> _onRegisterWithPhoneRequested(
    RegisterWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const PhoneRegisterInProgress());
    final normalizedPhone = _normalizePhoneToE164(event.phone);
    if (normalizedPhone == null) {
      emit(
        const PhoneRegisterFailure(
          message: 'Số điện thoại không hợp lệ. Vui lòng nhập đúng định dạng.',
        ),
      );
      return;
    }

    _pendingPhoneNumber = event.phone;
    _pendingPassword = event.password;
    _pendingFullName = event.fullName;

    final completer = Completer<String>();
    PhoneAuthCredential? autoVerifiedCredential;

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          autoVerifiedCredential = credential;
          if (!completer.isCompleted) {
            completer.complete('__AUTO_VERIFIED__');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('${e.code}: ${e.message ?? 'OTP send failed'}'),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      final verificationId = await completer.future;

      if (verificationId == '__AUTO_VERIFIED__') {
        if (autoVerifiedCredential == null) {
          emit(
            const PhoneRegisterFailure(
              message: 'Auto verification failed. Please try again.',
            ),
          );
          return;
        }

        await _completePhoneRegisterWithCredential(
          phoneCredential: autoVerifiedCredential!,
          emit: emit,
        );
        return;
      }

      _pendingVerificationId = verificationId;
      emit(PhoneOtpCodeSent(phone: event.phone));
    } catch (e) {
      emit(
        PhoneRegisterFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onPhoneOtpCodeSubmitted(
    PhoneOtpCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final verificationId = _pendingVerificationId;

    if (verificationId == null) {
      emit(const PhoneRegisterFailure(message: 'Invalid OTP session'));
      return;
    }

    emit(const PhoneRegisterInProgress());
    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: event.smsCode,
      );

      await _completePhoneRegisterWithCredential(
        phoneCredential: phoneCredential,
        emit: emit,
      );
    } catch (e) {
      emit(
        PhoneRegisterFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onResendPhoneOtpRequested(
    ResendPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final phone = _pendingPhoneNumber;
    final password = _pendingPassword;
    if (phone == null || password == null) {
      emit(const PhoneRegisterFailure(message: 'Invalid OTP session'));
      return;
    }
    add(
      RegisterWithPhoneRequested(
        phone: phone,
        password: password,
        fullName: _pendingFullName,
      ),
    );
  }

  Future<void> _onLoadCredentialsRequested(
    LoadCredentialsRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const CredentialsLoading());

    final cachedCredentialTypes = await secureStorage.getCredentialTypes();
    if (cachedCredentialTypes.isNotEmpty) {
      emit(CredentialsLoaded(credentialTypes: cachedCredentialTypes));
    }

    final CredentialsResponse result = await authRepository.getCredentials();
    if (!result.success) {
      if (cachedCredentialTypes.isNotEmpty) {
        return;
      }
      emit(CredentialsFailure(message: result.message));
      return;
    }

    final normalizedCredentialTypes = result.credentialTypes
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    await secureStorage.setCredentialTypes(normalizedCredentialTypes);
    emit(CredentialsLoaded(credentialTypes: normalizedCredentialTypes));
  }

  Future<void> _onLinkEmailRequested(
    LinkEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const LinkCredentialInProgress());
    final result = await authRepository.linkEmail(
      email: event.email,
      password: event.password,
    );
    if (!result.success) {
      emit(LinkCredentialFailure(message: result.message));
      return;
    }

    await _addLinkedCredentialTypeToCache('email');
    emit(const LinkCredentialSuccess(linkedType: 'email'));
    add(const LoadCredentialsRequested());
  }

  Future<void> _onLinkGoogleRequested(
    LinkGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const LinkCredentialInProgress());
    try {
      await _resetGoogleSessionForAccountPicker();
      final googleUser = await _signInWithTimeout();
      if (googleUser == null) {
        emit(const LinkCredentialFailure(message: 'Google linking canceled'));
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        emit(const LinkCredentialFailure(message: 'Google token not found'));
        return;
      }

      final result = await authRepository.linkGoogle(idToken: idToken);
      if (!result.success) {
        emit(LinkCredentialFailure(message: result.message));
        return;
      }

      await _addLinkedCredentialTypeToCache('google');
      emit(const LinkCredentialSuccess(linkedType: 'google'));
      add(const LoadCredentialsRequested());
    } catch (e) {
      emit(
        LinkCredentialFailure(
          message: _mapGoogleSignInError(e),
        ),
      );
    }
  }

  Future<void> _onStartLinkPhoneRequested(
    StartLinkPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const LinkCredentialInProgress());
    final normalizedPhone = _normalizePhoneToE164(event.phone);
    if (normalizedPhone == null) {
      emit(
        const LinkCredentialFailure(
          message: 'Số điện thoại không hợp lệ. Vui lòng nhập đúng định dạng.',
        ),
      );
      return;
    }

    _pendingLinkPhoneNumber = event.phone;
    _pendingLinkPhonePassword = event.password;

    final completer = Completer<String>();
    PhoneAuthCredential? autoVerifiedCredential;

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          autoVerifiedCredential = credential;
          if (!completer.isCompleted) {
            completer.complete('__AUTO_VERIFIED__');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('${e.code}: ${e.message ?? 'OTP send failed'}'),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      final verificationId = await completer.future;

      if (verificationId == '__AUTO_VERIFIED__') {
        if (autoVerifiedCredential == null) {
          emit(
            const LinkCredentialFailure(
              message: 'Auto verification failed. Please try again.',
            ),
          );
          return;
        }

        await _completeLinkPhoneWithCredential(
          phoneCredential: autoVerifiedCredential!,
          emit: emit,
        );
        return;
      }

      _pendingLinkPhoneVerificationId = verificationId;
      emit(LinkPhoneOtpCodeSent(phone: event.phone));
    } catch (e) {
      emit(
        LinkCredentialFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSubmitLinkPhoneOtpRequested(
    SubmitLinkPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final verificationId = _pendingLinkPhoneVerificationId;

    if (verificationId == null) {
      emit(const LinkCredentialFailure(message: 'Invalid OTP session'));
      return;
    }

    emit(const LinkCredentialInProgress());

    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: event.smsCode,
      );

      await _completeLinkPhoneWithCredential(
        phoneCredential: phoneCredential,
        emit: emit,
      );
    } catch (e) {
      emit(
        LinkCredentialFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onResendLinkPhoneOtpRequested(
    ResendLinkPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final phone = _pendingLinkPhoneNumber;
    if (phone == null) {
      emit(const LinkCredentialFailure(message: 'Invalid OTP session'));
      return;
    }

    add(
      StartLinkPhoneRequested(
        phone: phone,
        password: _pendingLinkPhonePassword,
      ),
    );
  }

  Future<void> _completePhoneRegisterWithCredential({
    required PhoneAuthCredential phoneCredential,
    required Emitter<AuthState> emit,
  }) async {
    final phone = _pendingPhoneNumber;
    final password = _pendingPassword;

    if (phone == null || password == null) {
      emit(const PhoneRegisterFailure(message: 'Invalid OTP session'));
      return;
    }

    final userCredential = await _firebaseAuth.signInWithCredential(
      phoneCredential,
    );
    final firebaseUser = userCredential.user;
    final firebaseIdToken = await firebaseUser?.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      emit(const PhoneRegisterFailure(message: 'Cannot get Firebase token'));
      return;
    }

    final result = await authRepository.registerWithPhone(
      phone: phone,
      password: password,
      firebaseIdToken: firebaseIdToken,
      fullName: _pendingFullName,
    );

    if (!result.success || result.accessToken == null) {
      emit(PhoneRegisterFailure(message: result.message));
      return;
    }

    await secureStorage.saveAuthTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken ?? '',
    );
    await secureStorage.setNeedsSetPassword(false);

    await UserProfileContext().saveProfile(
      fullName: result.fullName,
      avatarUrl: result.avatarUrl,
    );
    AppRouter.globalAppBarState.updateProfile(
      name: result.fullName,
      avatarUrl: result.avatarUrl,
    );

    await firebaseMessagingService.registerCurrentToken();
    await _firebaseAuth.signOut();
    emit(
      LoginSuccess(
        accessToken: result.accessToken!,
        user: {
          if (result.fullName != null) 'fullName': result.fullName,
          if (result.avatarUrl != null) 'avatarUrl': result.avatarUrl,
        },
      ),
    );
  }

  Future<void> _completeLinkPhoneWithCredential({
    required PhoneAuthCredential phoneCredential,
    required Emitter<AuthState> emit,
  }) async {
    final phone = _pendingLinkPhoneNumber;

    if (phone == null) {
      emit(const LinkCredentialFailure(message: 'Invalid OTP session'));
      return;
    }

    final userCredential = await _firebaseAuth.signInWithCredential(
      phoneCredential,
    );
    final firebaseUser = userCredential.user;
    final firebaseIdToken = await firebaseUser?.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      emit(const LinkCredentialFailure(message: 'Cannot get Firebase token'));
      return;
    }

    final result = await authRepository.linkPhone(
      phone: phone,
      firebaseIdToken: firebaseIdToken,
      password: _pendingLinkPhonePassword,
    );

    await _firebaseAuth.signOut();

    if (!result.success) {
      emit(LinkCredentialFailure(message: result.message));
      return;
    }

    await _addLinkedCredentialTypeToCache('phone');
    emit(const LinkCredentialSuccess(linkedType: 'phone'));
    add(const LoadCredentialsRequested());
  }

  /// Handle Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LogoutInProgress());
    try {
      // Clear lightweight local context first so next login never sees stale profile/cache.
      await BusinessContext().clear();
      await UserProfileContext().clear();
      await CacheManager().clearAll();
      await secureStorage.clearNeedsSetPassword();
      await secureStorage.clearCredentialTypes();
      AppRouter.globalAppBarState.reset();

      await firebaseMessagingService.unregisterCurrentToken();
      await authRepository.logout();
      await _resetGoogleSessionForAccountPicker();
    } catch (e) {
      debugPrint('Logout error (ignored): $e');
    }

    // Notify UI first so current feature screens are disposed before DB cleanup.
    emit(LogoutSuccess());

    // Run DB scope switch asynchronously to avoid blocking next auth events.
    unawaited(
      DatabaseManager().clearForLogout().catchError((Object e) {
        debugPrint('Post-logout DB cleanup error (ignored): $e');
      }),
    );
  }

  Future<void> _addLinkedCredentialTypeToCache(String type) async {
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      return;
    }

    final current = await secureStorage.getCredentialTypes();
    final updated = {...current, normalizedType}.toList();
    await secureStorage.setCredentialTypes(updated);
  }

  /// Handle Clear Error
  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  Future<void> _resetGoogleSessionForAccountPicker() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }

  Future<GoogleSignInAccount?> _signInWithTimeout() {
    return _googleSignIn.signIn().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('Google sign-in timed out'),
    );
  }

  String _mapGoogleSignInError(Object error) {
    if (error is TimeoutException) {
      return 'Google sign-in timed out. Please try again.';
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final details = '${error.message ?? ''} ${error.details ?? ''}'.toLowerCase();
      if (code.contains('sign_in_failed') || details.contains('developer_error')) {
        return 'Google Sign-In configuration is invalid on this device build. Please check Firebase Android app config and Play Services.';
      }
    }

    return ApiErrorMessageParser.parse(error);
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

  String? _normalizePhoneToE164(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.isEmpty) return null;

    if (cleaned.startsWith('+')) {
      final numeric = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      final e164 = '+$numeric';
      return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(e164) ? e164 : null;
    }

    final numeric = cleaned.replaceAll(RegExp(r'\D'), '');
    if (numeric.isEmpty) return null;

    if (numeric.startsWith('0')) {
      final normalized = '+84${numeric.substring(1)}';
      return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized)
          ? normalized
          : null;
    }

    if (numeric.startsWith('84')) {
      final normalized = '+$numeric';
      return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized)
          ? normalized
          : null;
    }

    if (numeric.length == 9) {
      final normalized = '+84$numeric';
      return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized)
          ? normalized
          : null;
    }

    return null;
  }
}
