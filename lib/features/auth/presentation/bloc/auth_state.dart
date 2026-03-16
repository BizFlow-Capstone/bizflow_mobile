import 'auth_bloc.dart';

// Auth States - UI states
abstract class AuthState {
  const AuthState();
}

// Initial / Checking State
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking stored token on app startup
class AuthCheckingStatus extends AuthState {
  const AuthCheckingStatus();
}

// Loading State
class AuthLoading extends AuthState {
  const AuthLoading();
}

// Signup States
class SignupInProgress extends AuthState {
  const SignupInProgress();
}

class SignupSuccess extends AuthState {
  final String phoneNumber;

  const SignupSuccess({required this.phoneNumber});
}

class SignupFailure extends AuthState {
  final AuthErrorCode errorCode;

  const SignupFailure({required this.errorCode});
}

// OTP Verification States
class OtpVerificationInProgress extends AuthState {
  const OtpVerificationInProgress();
}

class OtpVerificationSuccess extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  const OtpVerificationSuccess({required this.token, required this.user});
}

class OtpVerificationFailure extends AuthState {
  final AuthErrorCode errorCode;

  const OtpVerificationFailure({required this.errorCode});
}

// Login States
class LoginInProgress extends AuthState {
  const LoginInProgress();
}

class LoginSuccess extends AuthState {
  final String accessToken;
  final Map<String, dynamic> user;

  const LoginSuccess({required this.accessToken, required this.user});
}

class LoginFailure extends AuthState {
  final AuthErrorCode errorCode;
  final String? serverMessage;

  const LoginFailure({required this.errorCode, this.serverMessage});
}

/// Google login returned isNewAccount=true — navigate to SetPassword
class GoogleLoginSetPasswordRequired extends AuthState {
  final String accessToken;
  final String refreshToken;

  const GoogleLoginSetPasswordRequired({
    required this.accessToken,
    required this.refreshToken,
  });
}

// Set Password States
class SetPasswordInProgress extends AuthState {
  const SetPasswordInProgress();
}

class SetPasswordSuccess extends AuthState {
  const SetPasswordSuccess();
}

class SetPasswordFailure extends AuthState {
  final String message;

  const SetPasswordFailure({required this.message});
}

// Authenticated State
class AuthAuthenticated extends AuthState {
  final String accessToken;

  const AuthAuthenticated({required this.accessToken});
}

class NeedsSetPasswordOnResume extends AuthState {
  const NeedsSetPasswordOnResume();
}

// Unauthenticated State
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// Logout States
class LogoutInProgress extends AuthState {
  const LogoutInProgress();
}

class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}

class CredentialsLoading extends AuthState {
  const CredentialsLoading();
}

class CredentialsLoaded extends AuthState {
  final List<String> credentialTypes;

  const CredentialsLoaded({required this.credentialTypes});
}

class CredentialsFailure extends AuthState {
  final String message;

  const CredentialsFailure({required this.message});
}

class LinkCredentialInProgress extends AuthState {
  const LinkCredentialInProgress();
}

class LinkCredentialSuccess extends AuthState {
  final String linkedType;

  const LinkCredentialSuccess({required this.linkedType});
}

class LinkCredentialFailure extends AuthState {
  final String message;

  const LinkCredentialFailure({required this.message});
}

class LinkPhoneOtpCodeSent extends AuthState {
  final String phone;

  const LinkPhoneOtpCodeSent({required this.phone});
}

class PhoneRegisterInProgress extends AuthState {
  const PhoneRegisterInProgress();
}

class PhoneOtpCodeSent extends AuthState {
  final String phone;

  const PhoneOtpCodeSent({required this.phone});
}

class PhoneRegisterFailure extends AuthState {
  final String message;

  const PhoneRegisterFailure({required this.message});
}

// Error State
class AuthError extends AuthState {
  final AuthErrorCode errorCode;

  const AuthError({required this.errorCode});
}
