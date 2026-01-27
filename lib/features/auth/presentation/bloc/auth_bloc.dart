import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC - State Management for Authentication
/// Xử lý tất cả auth events: signup, login, verify OTP, logout
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    // Handle Signup Events
    on<SignupRequested>(_onSignupRequested);
    on<GoogleSignupRequested>(_onGoogleSignupRequested);

    // Handle Login Events
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);

    // Handle OTP Events
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);

    // Handle General Events
    on<LogoutRequested>(_onLogoutRequested);
    on<ClearAuthError>(_onClearAuthError);
  }

  /// Handle Signup
  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupInProgress());
    try {
      // TODO: Call repository to signup
      // final result = await _authRepository.signup(
      //   name: event.name,
      //   phone: event.phone,
      //   email: event.email,
      //   password: event.password,
      // );

      // Mock success
      await Future.delayed(const Duration(seconds: 2));
      emit(SignupSuccess(phoneNumber: event.phone));
    } catch (e) {
      emit(SignupFailure(message: e.toString()));
    }
  }

  /// Handle Google Signup
  Future<void> _onGoogleSignupRequested(
    GoogleSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupInProgress());
    try {
      // TODO: Call repository to signup with Google
      // final result = await _authRepository.googleSignup(
      //   idToken: event.idToken,
      //   email: event.email,
      //   name: event.name,
      // );

      // Mock success
      await Future.delayed(const Duration(seconds: 2));
      emit(SignupSuccess(phoneNumber: '+84123456789'));
    } catch (e) {
      emit(SignupFailure(message: e.toString()));
    }
  }

  /// Handle Login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginInProgress());
    try {
      // TODO: Call repository to login
      // final result = await _authRepository.login(
      //   email: event.email.isNotEmpty ? event.email : null,
      //   phone: event.phone.isNotEmpty ? event.phone : null,
      //   password: event.password,
      // );

      // Mock success
      await Future.delayed(const Duration(seconds: 2));
      emit(LoginSuccess(
        token: 'mock_token_123',
        user: {'id': '1', 'email': event.email, 'phone': event.phone},
      ));
    } catch (e) {
      emit(LoginFailure(message: e.toString()));
    }
  }

  /// Handle Google Login
  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginInProgress());
    try {
      // TODO: Call repository to login with Google
      // final result = await _authRepository.googleLogin(
      //   idToken: event.idToken,
      // );

      // Mock success
      await Future.delayed(const Duration(seconds: 2));
      emit(LoginSuccess(
        token: 'mock_google_token_123',
        user: {'id': '1', 'email': 'user@google.com'},
      ));
    } catch (e) {
      emit(LoginFailure(message: e.toString()));
    }
  }

  /// Handle OTP Verification
  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(OtpVerificationInProgress());
    try {
      // TODO: Call repository to verify OTP
      // final result = await _authRepository.verifyOtp(
      //   phone: event.phone,
      //   otpCode: event.otpCode,
      // );

      // Mock success
      await Future.delayed(const Duration(seconds: 2));
      if (event.otpCode == '000000') {
        emit(OtpVerificationFailure(message: 'Invalid OTP code'));
      } else {
        emit(OtpVerificationSuccess(
          token: 'mock_token_after_otp',
          user: {'id': '1', 'phone': event.phone, 'verified': true},
        ));
      }
    } catch (e) {
      emit(OtpVerificationFailure(message: e.toString()));
    }
  }

  /// Handle Resend OTP
  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // TODO: Call repository to resend OTP
      // final result = await _authRepository.resendOtp(
      //   phone: event.phone,
      // );

      // Mock success - just show success message in UI
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      // Silently fail - UI handles retry
    }
  }

  /// Handle Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // TODO: Call repository to logout
      // await _authRepository.logout();

      // Mock success
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle Clear Error
  void _onClearAuthError(
    ClearAuthError event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthInitial());
  }
}
