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
  int _phoneRegisterFlowVersion = 0;

  String? _pendingLinkPhoneNumber;
  String? _pendingLinkPhonePassword;
  String? _pendingLinkPhoneVerificationId;

  String? _pendingForgotPasswordIdentifier;
  ForgotPasswordChannel? _pendingForgotPasswordChannel;
  String? _pendingForgotPasswordVerificationId;

  static const String _googleOnboardingStepLinkPhone = 'link_phone';
  static const String _googleOnboardingStepSetPassword = 'set_password';

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
    on<CancelPhoneRegisterFlowRequested>(_onCancelPhoneRegisterFlowRequested);
    on<LoadCredentialsRequested>(_onLoadCredentialsRequested);
    on<LinkEmailRequested>(_onLinkEmailRequested);
    on<LinkGoogleRequested>(_onLinkGoogleRequested);
    on<StartLinkPhoneRequested>(_onStartLinkPhoneRequested);
    on<SubmitLinkPhoneOtpRequested>(_onSubmitLinkPhoneOtpRequested);
    on<ResendLinkPhoneOtpRequested>(_onResendLinkPhoneOtpRequested);
    on<ForgotPasswordSendOtpRequested>(_onForgotPasswordSendOtpRequested);
    on<ForgotPasswordVerifyOtpRequested>(_onForgotPasswordVerifyOtpRequested);
    on<ForgotPasswordResetRequested>(_onForgotPasswordResetRequested);
    on<LoadProfileRequested>(_onLoadProfileRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<UpdateAvatarRequested>(_onUpdateAvatarRequested);
    on<RemoveAvatarRequested>(_onRemoveAvatarRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthOnboardingCompleted>(_onAuthOnboardingCompleted);
    on<ClearAuthError>(_onClearAuthError);
  }

  /// Check stored token on app startup → route to home or login
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthCheckingStatus());
    try {
      final loggedIn = await authRepository.isLoggedIn();
      if (loggedIn) {
        await DatabaseManager().initialize();
        final onboardingStep = await secureStorage.getGoogleOnboardingStep();
        if (onboardingStep == _googleOnboardingStepLinkPhone) {
          emit(const NeedsGooglePhoneLinkOnResume());
          return;
        }
        if (onboardingStep == _googleOnboardingStepSetPassword) {
          emit(const NeedsSetPasswordOnResume());
          return;
        }

        final cachedCredentialTypes = await secureStorage.getCredentialTypes();
        if (_isGooglePhoneLinkRequired(cachedCredentialTypes)) {
          emit(const NeedsGooglePhoneLinkOnResume());
          return;
        }

        if (cachedCredentialTypes.isEmpty) {
          final credentialResult = await authRepository.getCredentials();
          if (credentialResult.success) {
            final normalized = credentialResult.credentialTypes
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
            if (normalized.isNotEmpty) {
              await secureStorage.setCredentialTypes(normalized);
            }
            if (_isGooglePhoneLinkRequired(normalized)) {
              emit(const NeedsGooglePhoneLinkOnResume());
              return;
            }
          }
        }

        final needsSetPassword = await secureStorage.getNeedsSetPassword();
        if (needsSetPassword) {
          emit(const NeedsSetPasswordOnResume());
          return;
        }
        try {
          await firebaseMessagingService.registerCurrentToken().timeout(
            const Duration(seconds: 2),
          );
        } catch (e) {
          debugPrint(
            'AuthBloc: Token registration timed out or failed, proceeding...',
          );
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

      final credentialTypes = await _resolveCredentialTypes(result);
      if (credentialTypes.isNotEmpty) {
        await secureStorage.setCredentialTypes(credentialTypes);
      }

      final requiresPhoneLink = !credentialTypes.contains('phone');
      final requiresSetPassword =
          (result.hasPassword == false) || (result.isNewAccount == true);

      if (requiresSetPassword) {
        // Priority: set password first, then link phone if still missing.
        await secureStorage.setNeedsSetPassword(true);
        await secureStorage.setGoogleOnboardingStep(
          _googleOnboardingStepSetPassword,
        );
        emit(
          GoogleLoginSetPasswordRequired(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken ?? '',
          ),
        );
      } else if (requiresPhoneLink) {
        await secureStorage.setNeedsSetPassword(false);
        await secureStorage.setGoogleOnboardingStep(
          _googleOnboardingStepLinkPhone,
        );
        emit(const GoogleLoginPhoneLinkRequired());
      } else {
        await secureStorage.setNeedsSetPassword(false);
        await secureStorage.clearGoogleOnboardingStep();
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
      final normalizedMessageCode = result.messageCode?.trim();
      final normalizedMessage = result.message.trim().toLowerCase();
      final isAlreadySet =
          normalizedMessageCode == 'AUTH_PASSWORD_ALREADY_SET' ||
          normalizedMessage.contains('mật khẩu đã được đặt') ||
          normalizedMessage.contains('mat khau da duoc dat');

      if (result.success || isAlreadySet) {
        await secureStorage.setNeedsSetPassword(false);

        final credentialTypes = await _getCredentialTypesForOnboarding();
        final needsPhoneLink = !credentialTypes.contains('phone');

        if (needsPhoneLink) {
          await secureStorage.setGoogleOnboardingStep(
            _googleOnboardingStepLinkPhone,
          );
          emit(const GoogleLoginPhoneLinkRequired());
          return;
        }

        await secureStorage.clearGoogleOnboardingStep();
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
    emit(const PhoneRegisterSendOtpInProgress());
    final normalizedPhone = _normalizePhoneToE164(event.phone);
    if (normalizedPhone == null) {
      emit(
        const PhoneRegisterFailure(
          message: 'auth.firebase_invalid_phone_format',
        ),
      );
      return;
    }

    _pendingPhoneNumber = event.phone;
    _pendingPassword = event.password;
    _pendingFullName = event.fullName;
    _pendingVerificationId = null;
    final requestVersion = ++_phoneRegisterFlowVersion;

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
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            // Ensure request always leaves loading state when auto-retrieval ends.
            completer.complete(verificationId);
          }
        },
      );

      final verificationId = await completer.future.timeout(
        const Duration(seconds: 70),
        onTimeout: () => throw TimeoutException('Phone OTP request timed out'),
      );
      if (!_isPhoneRegisterFlowActive(requestVersion) || emit.isDone) {
        return;
      }

      if (verificationId == '__AUTO_VERIFIED__') {
        if (autoVerifiedCredential == null) {
          emit(
            const PhoneRegisterFailure(
              message: 'auth.firebase_auto_verification_failed',
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
      if (!_isPhoneRegisterFlowActive(requestVersion) || emit.isDone) {
        return;
      }
      emit(PhoneRegisterFailure(message: _mapPhoneAuthError(e)));
    }
  }

  Future<void> _onPhoneOtpCodeSubmitted(
    PhoneOtpCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final verificationId = _pendingVerificationId;

    if (verificationId == null) {
      emit(const PhoneRegisterFailure(message: 'auth.firebase_invalid_otp_session'));
      return;
    }

    emit(const PhoneRegisterVerifyOtpInProgress());
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
      emit(PhoneRegisterFailure(message: _mapPhoneAuthError(e)));
    }
  }

  Future<void> _onResendPhoneOtpRequested(
    ResendPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final phone = _pendingPhoneNumber;
    final password = _pendingPassword;
    if (phone == null || password == null) {
      emit(const PhoneRegisterFailure(message: 'auth.firebase_invalid_otp_session'));
      return;
    }

    emit(const PhoneRegisterResendOtpInProgress());
    final normalizedPhone = _normalizePhoneToE164(phone);
    if (normalizedPhone == null) {
      emit(
        const PhoneRegisterFailure(
          message: 'auth.firebase_invalid_phone_format',
        ),
      );
      return;
    }

    final requestVersion = ++_phoneRegisterFlowVersion;
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
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            // Ensure request always leaves loading state when auto-retrieval ends.
            completer.complete(verificationId);
          }
        },
      );

      final verificationId = await completer.future.timeout(
        const Duration(seconds: 70),
        onTimeout: () => throw TimeoutException('Phone OTP resend timed out'),
      );
      if (!_isPhoneRegisterFlowActive(requestVersion) || emit.isDone) {
        return;
      }

      if (verificationId == '__AUTO_VERIFIED__') {
        if (autoVerifiedCredential == null) {
          emit(
            const PhoneRegisterFailure(
              message: 'auth.firebase_auto_verification_failed',
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
      emit(PhoneOtpCodeSent(phone: phone));
    } catch (e) {
      if (!_isPhoneRegisterFlowActive(requestVersion) || emit.isDone) {
        return;
      }
      emit(PhoneRegisterFailure(message: _mapPhoneAuthError(e)));
    }
  }

  void _onCancelPhoneRegisterFlowRequested(
    CancelPhoneRegisterFlowRequested event,
    Emitter<AuthState> emit,
  ) {
    _cancelPhoneRegisterFlow(clearPendingCredentials: true);
    emit(const AuthInitial());
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

    await CacheManager().fetchWithSWR<List<String>>(
      key: 'auth_credentials_methods',
      fetcher: ({cancelToken}) async {
        final CredentialsResponse result = await authRepository
            .getCredentials();
        if (!result.success) {
          throw Exception(result.message);
        }
        return result.credentialTypes
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      },
      fromJson: (json) {
        final raw = json['types'];
        if (raw is! List) {
          return <String>[];
        }
        return raw.map((e) => e.toString()).toList();
      },
      toJson: (types) => {'types': types},
      onData: (types, _) {
        if (types.isNotEmpty) {
          secureStorage.setCredentialTypes(types);
        }
        if (!emit.isDone) {
          emit(CredentialsLoaded(credentialTypes: types));
        }
      },
      onError: (error) {
        if (cachedCredentialTypes.isNotEmpty || emit.isDone) {
          return;
        }
        emit(CredentialsFailure(message: ApiErrorMessageParser.parse(error)));
      },
    );
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
        emit(const LinkCredentialFailure(message: 'auth.firebase_google_canceled'));
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        emit(const LinkCredentialFailure(message: 'auth.firebase_google_token_not_found'));
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
      emit(LinkCredentialFailure(message: _mapGoogleSignInError(e)));
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
          message: 'auth.firebase_invalid_phone_format',
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
            completer.completeError(e);
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
              message: 'auth.firebase_auto_verification_failed',
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
      emit(LinkCredentialFailure(message: _mapPhoneAuthError(e)));
    }
  }

  Future<void> _onSubmitLinkPhoneOtpRequested(
    SubmitLinkPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final verificationId = _pendingLinkPhoneVerificationId;

    if (verificationId == null) {
      emit(const LinkCredentialFailure(message: 'auth.firebase_invalid_otp_session'));
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
      emit(LinkCredentialFailure(message: _mapPhoneAuthError(e)));
    }
  }

  Future<void> _onResendLinkPhoneOtpRequested(
    ResendLinkPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final phone = _pendingLinkPhoneNumber;
    if (phone == null) {
      emit(const LinkCredentialFailure(message: 'auth.firebase_invalid_otp_session'));
      return;
    }

    add(
      StartLinkPhoneRequested(
        phone: phone,
        password: _pendingLinkPhonePassword,
      ),
    );
  }

  Future<void> _onForgotPasswordSendOtpRequested(
    ForgotPasswordSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ForgotPasswordInProgress());
    if (event.channel == ForgotPasswordChannel.phone) {
      await _sendForgotPasswordOtpByPhone(
        identifier: event.identifier,
        emit: emit,
      );
      return;
    }

    final result = await authRepository.forgotPasswordSendOtp(
      identifier: event.identifier,
    );
    if (!result.success) {
      emit(ForgotPasswordFailure(message: result.message));
      return;
    }

    _pendingForgotPasswordIdentifier = event.identifier;
    _pendingForgotPasswordChannel = event.channel;
    _pendingForgotPasswordVerificationId = null;
    emit(
      ForgotPasswordOtpSent(
        destination: event.identifier,
        channel: event.channel,
      ),
    );
  }

  Future<void> _onForgotPasswordVerifyOtpRequested(
    ForgotPasswordVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ForgotPasswordInProgress());

    final AuthResponse result;
    if (event.channel == ForgotPasswordChannel.phone) {
      result = await _verifyForgotPasswordOtpByPhone(
        smsCode: event.otpCode,
      );
    } else {
      result = await authRepository.forgotPasswordVerifyOtp(
        identifier: event.identifier,
        otpCode: event.otpCode,
      );
    }

    if (!result.success || result.accessToken == null) {
      emit(ForgotPasswordFailure(message: result.message));
      return;
    }

    await secureStorage.write(
      key: SecureStorageKeys.accessToken,
      value: result.accessToken!,
    );

    _pendingForgotPasswordVerificationId = null;
    emit(const ForgotPasswordOtpVerified());
  }

  Future<void> _onForgotPasswordResetRequested(
    ForgotPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ForgotPasswordInProgress());
    final result = await authRepository.forgotPasswordReset(
      password: event.password,
    );
    if (!result.success) {
      emit(ForgotPasswordFailure(message: result.message));
      return;
    }

    await secureStorage.clearAuthTokens();
    _pendingForgotPasswordIdentifier = null;
    _pendingForgotPasswordChannel = null;
    _pendingForgotPasswordVerificationId = null;
    emit(const ForgotPasswordResetSuccess());
  }

  Future<void> _sendForgotPasswordOtpByPhone({
    required String identifier,
    required Emitter<AuthState> emit,
  }) async {
    final normalizedPhone = _normalizePhoneToE164(identifier);
    if (normalizedPhone == null) {
      emit(
        const ForgotPasswordFailure(message: 'auth.firebase_invalid_phone_format'),
      );
      return;
    }

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
            completer.completeError(e);
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
      _pendingForgotPasswordIdentifier = identifier;
      _pendingForgotPasswordChannel = ForgotPasswordChannel.phone;

      if (verificationId == '__AUTO_VERIFIED__') {
        if (autoVerifiedCredential == null) {
          emit(
            const ForgotPasswordFailure(
              message: 'auth.firebase_auto_verification_failed',
            ),
          );
          return;
        }

        final result = await _verifyForgotPasswordWithPhoneCredential(
          phoneCredential: autoVerifiedCredential!,
        );

        if (!result.success || result.accessToken == null) {
          emit(ForgotPasswordFailure(message: result.message));
          return;
        }

        await secureStorage.write(
          key: SecureStorageKeys.accessToken,
          value: result.accessToken!,
        );
        emit(const ForgotPasswordOtpVerified());
        return;
      }

      _pendingForgotPasswordVerificationId = verificationId;
      emit(
        ForgotPasswordOtpSent(
          destination: identifier,
          channel: ForgotPasswordChannel.phone,
        ),
      );
    } catch (e) {
      emit(ForgotPasswordFailure(message: _mapPhoneAuthError(e)));
    }
  }

  Future<AuthResponse> _verifyForgotPasswordOtpByPhone({
    required String smsCode,
  }) async {
    final verificationId = _pendingForgotPasswordVerificationId;
    if (verificationId == null) {
      return AuthResponse(
        success: false,
        message: 'auth.firebase_invalid_otp_session',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return await _verifyForgotPasswordWithPhoneCredential(
        phoneCredential: credential,
      );
    } catch (e) {
      return AuthResponse(success: false, message: _mapPhoneAuthError(e));
    }
  }

  Future<AuthResponse> _verifyForgotPasswordWithPhoneCredential({
    required PhoneAuthCredential phoneCredential,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(
        phoneCredential,
      );
      final firebaseUser = userCredential.user;
      final firebaseIdToken = await firebaseUser?.getIdToken();

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        return AuthResponse(
          success: false,
          message: 'auth.firebase_token_unavailable',
        );
      }

      final result = await authRepository.forgotPasswordVerifyOtp(
        firebaseIdToken: firebaseIdToken,
      );
      await _firebaseAuth.signOut();
      return result;
    } catch (e) {
      return AuthResponse(success: false, message: _mapPhoneAuthError(e));
    }
  }

  Future<void> _onLoadProfileRequested(
    LoadProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await authRepository.getProfile();
    if (!result.success) {
      emit(ProfileUpdateFailure(message: result.message));
      return;
    }

    await UserProfileContext().saveProfile(
      fullName: result.fullName,
      avatarUrl: result.avatarUrl,
      email: UserProfileContext().email,
      phone: UserProfileContext().phone,
    );
    AppRouter.globalAppBarState.updateProfile(
      name: result.fullName,
      avatarUrl: result.avatarUrl,
    );
    emit(
      ProfileLoaded(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
        taxCode: result.taxCode,
      ),
    );
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await authRepository.updateProfile(
      fullName: event.fullName,
      taxCode: event.taxCode,
    );
    if (!result.success) {
      emit(ProfileUpdateFailure(message: result.message));
      return;
    }

    await UserProfileContext().saveProfile(
      fullName: result.fullName,
      avatarUrl: result.avatarUrl,
      email: UserProfileContext().email,
      phone: UserProfileContext().phone,
      taxCode: result.taxCode,
    );
    AppRouter.globalAppBarState.updateProfile(
      name: result.fullName,
      avatarUrl: result.avatarUrl,
    );
    emit(ProfileUpdateSuccess(message: result.message));
    emit(
      ProfileLoaded(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
        taxCode: result.taxCode,
      ),
    );
  }

  Future<void> _onUpdateAvatarRequested(
    UpdateAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await authRepository.updateAvatar(
      avatarPath: event.avatarPath,
    );
    if (!result.success) {
      emit(ProfileUpdateFailure(message: result.message));
      return;
    }

    await UserProfileContext().saveProfile(
      fullName: result.fullName,
      avatarUrl: result.avatarUrl,
      email: UserProfileContext().email,
      phone: UserProfileContext().phone,
      taxCode: result.taxCode,
    );
    AppRouter.globalAppBarState.updateProfile(
      name: result.fullName,
      avatarUrl: result.avatarUrl,
    );
    emit(ProfileUpdateSuccess(message: result.message));
    emit(
      ProfileLoaded(
        fullName: result.fullName,
        avatarUrl: result.avatarUrl,
        taxCode: result.taxCode,
      ),
    );
  }

  Future<void> _onRemoveAvatarRequested(
    RemoveAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await authRepository.removeAvatar();
    if (!result.success) {
      emit(ProfileUpdateFailure(message: result.message));
      return;
    }

    await UserProfileContext().saveProfile(
      fullName: result.fullName,
      avatarUrl: null,
      email: UserProfileContext().email,
      phone: UserProfileContext().phone,
      taxCode: result.taxCode,
    );
    AppRouter.globalAppBarState.updateProfile(
      name: result.fullName,
      avatarUrl: null,
    );
    emit(ProfileUpdateSuccess(message: result.message));
    emit(
      ProfileLoaded(
        fullName: result.fullName,
        avatarUrl: null,
        taxCode: result.taxCode,
      ),
    );
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ChangePasswordInProgress());
    final result = await authRepository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );

    if (!result.success) {
      emit(ChangePasswordFailure(message: result.message));
      return;
    }

    emit(ChangePasswordSuccess(message: result.message));
    await authRepository.logoutAll();
    add(const LogoutRequested());
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const DeleteAccountInProgress());
    final result = await authRepository.deleteAccount(password: event.password);

    if (!result.success) {
      emit(DeleteAccountFailure(message: result.message));
      return;
    }

    await secureStorage.clearAuthTokens();
    await secureStorage.clearGoogleOnboardingStep();
    await secureStorage.setNeedsSetPassword(false);
    await secureStorage.clearRegisterTaxCode();
    await UserProfileContext().clear();
    await BusinessContext().clear();
    await CacheManager().clearAll();
    await DatabaseManager().clearForLogout();

    emit(DeleteAccountSuccess(message: result.message));
    emit(const LogoutSuccess());
  }

  Future<void> _completePhoneRegisterWithCredential({
    required PhoneAuthCredential phoneCredential,
    required Emitter<AuthState> emit,
  }) async {
    final phone = _pendingPhoneNumber;
    final password = _pendingPassword;

    if (phone == null || password == null) {
      emit(const PhoneRegisterFailure(message: 'auth.firebase_invalid_otp_session'));
      return;
    }

    final userCredential = await _firebaseAuth.signInWithCredential(
      phoneCredential,
    );
    final firebaseUser = userCredential.user;
    final firebaseIdToken = await firebaseUser?.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      emit(const PhoneRegisterFailure(message: 'auth.firebase_token_unavailable'));
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
    emit(const PhoneRegisterGoogleLinkRequired());
  }

  Future<void> _completeLinkPhoneWithCredential({
    required PhoneAuthCredential phoneCredential,
    required Emitter<AuthState> emit,
  }) async {
    final phone = _pendingLinkPhoneNumber;

    if (phone == null) {
      emit(const LinkCredentialFailure(message: 'auth.firebase_invalid_otp_session'));
      return;
    }

    final userCredential = await _firebaseAuth.signInWithCredential(
      phoneCredential,
    );
    final firebaseUser = userCredential.user;
    final firebaseIdToken = await firebaseUser?.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      emit(const LinkCredentialFailure(message: 'auth.firebase_token_unavailable'));
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

    final onboardingStep = await secureStorage.getGoogleOnboardingStep();
    if (onboardingStep == _googleOnboardingStepLinkPhone) {
      final needsSetPassword = await secureStorage.getNeedsSetPassword();
      if (needsSetPassword) {
        await secureStorage.setGoogleOnboardingStep(
          _googleOnboardingStepSetPassword,
        );
        emit(
          const GoogleLoginSetPasswordRequired(
            accessToken: '',
            refreshToken: '',
          ),
        );
        return;
      }

      await secureStorage.setNeedsSetPassword(false);
      await secureStorage.clearGoogleOnboardingStep();
      emit(const LinkCredentialSuccess(linkedType: 'phone'));
      return;
    }

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
      await secureStorage.clearGoogleOnboardingStep();
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

  bool _isPhoneRegisterFlowActive(int version) {
    return _phoneRegisterFlowVersion == version;
  }

  void _cancelPhoneRegisterFlow({required bool clearPendingCredentials}) {
    _phoneRegisterFlowVersion++;
    _pendingVerificationId = null;
    if (clearPendingCredentials) {
      _pendingPhoneNumber = null;
      _pendingPassword = null;
      _pendingFullName = null;
    }
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

  String _googleSignInGenericErrorMessage() =>
      'auth.firebase_google_unavailable';

  String _phoneAuthGenericErrorMessage() =>
      'auth.firebase_phone_verification_unavailable';

  String _invalidPhoneFormatMessage() => 'auth.firebase_invalid_phone_format';

  String _mapGoogleSignInError(Object error) {
    if (error is TimeoutException) {
      return 'auth.firebase_google_timeout';
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final details = '${error.message ?? ''} ${error.details ?? ''}'
          .toLowerCase();

      if (code.contains('sign_in_canceled') ||
          details.contains('sign_in_canceled') ||
          details.contains('canceled')) {
        return 'auth.firebase_google_canceled';
      }

      if (code.contains('network') || details.contains('network')) {
        return 'auth.firebase_network_error';
      }

      if (code.contains('sign_in_failed') ||
          details.contains('developer_error')) {
        return 'auth.firebase_google_config_invalid';
      }

      if (details.contains('10:') || details.contains('api exception: 10')) {
        return 'auth.firebase_google_config_mismatch';
      }

      return _googleSignInGenericErrorMessage();
    }

    if (error is FirebaseAuthException) {
      final code = error.code.toLowerCase();
      if (code == 'account-exists-with-different-credential') {
        return 'auth.firebase_google_account_exists_diff_credential';
      }
      if (code == 'user-disabled') {
        return 'auth.firebase_user_disabled';
      }
      if (code == 'network-request-failed') {
        return 'auth.firebase_network_error';
      }
      return _googleSignInGenericErrorMessage();
    }

    return _googleSignInGenericErrorMessage();
  }

  String _mapPhoneAuthError(Object error) {
    if (error is FirebaseAuthException) {
      final code = error.code.toLowerCase();

      if (code == 'invalid-phone-number') {
        return _invalidPhoneFormatMessage();
      }
      if (code == 'too-many-requests' || code == 'quota-exceeded') {
        return 'auth.firebase_too_many_requests';
      }
      if (code == 'network-request-failed') {
        return 'auth.firebase_network_error';
      }
      if (code == 'session-expired' || code == 'invalid-verification-code') {
        return 'auth.firebase_otp_invalid_or_expired';
      }
      if (code == 'code-expired') {
        return 'auth.firebase_otp_expired';
      }
      if (code == 'missing-verification-code') {
        return 'auth.firebase_otp_required';
      }
      if (code == 'invalid-credential') {
        return 'auth.firebase_invalid_credential';
      }

      final rawMessage = (error.message ?? '').toLowerCase();
      if (rawMessage.contains('too_long') || rawMessage.contains('too long')) {
        return 'auth.firebase_phone_too_long';
      }

      return _phoneAuthGenericErrorMessage();
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final details = '${error.message ?? ''} ${error.details ?? ''}'
          .toLowerCase();

      if (code.contains('network') || details.contains('network')) {
        return 'auth.firebase_network_error';
      }

      if (details.contains('too_long') || details.contains('too long')) {
        return 'auth.firebase_phone_too_long';
      }

      if (details.contains('invalid-phone-number')) {
        return _invalidPhoneFormatMessage();
      }

      return _phoneAuthGenericErrorMessage();
    }

    return _phoneAuthGenericErrorMessage();
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

  bool _isGooglePhoneLinkRequired(List<String> credentialTypes) {
    final normalized = credentialTypes
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    return normalized.contains('google') && !normalized.contains('phone');
  }

  Future<List<String>> _resolveCredentialTypes(AuthResponse result) async {
    final fromLogin = result.credentialTypes
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (fromLogin.isNotEmpty) {
      return fromLogin;
    }

    final fromCache = await secureStorage.getCredentialTypes();
    if (fromCache.isNotEmpty) {
      return fromCache
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    final fetched = await authRepository.getCredentials();
    if (!fetched.success) {
      return const <String>[];
    }

    return fetched.credentialTypes
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<List<String>> _getCredentialTypesForOnboarding() async {
    final fromCache = await secureStorage.getCredentialTypes();
    if (fromCache.isNotEmpty) {
      return fromCache
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    final fetched = await authRepository.getCredentials();
    if (!fetched.success) {
      return const <String>[];
    }

    final normalized = fetched.credentialTypes
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (normalized.isNotEmpty) {
      await secureStorage.setCredentialTypes(normalized);
    }

    return normalized;
  }

  Future<void> _onAuthOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    final token = await secureStorage.getAccessToken();
    emit(AuthAuthenticated(accessToken: token ?? ''));
  }
}
