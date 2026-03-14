// Auth Events - User actions
abstract class AuthEvent {
  const AuthEvent();
}

/// Called on app startup to check if user is still authenticated
class AppStarted extends AuthEvent {
  const AppStarted();
}

// Signup Events
class SignupRequested extends AuthEvent {
  final String name;
  final String phone;
  final String email;
  final String password;

  const SignupRequested({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });
}

class GoogleSignupRequested extends AuthEvent {
  final String idToken;
  final String email;
  final String name;

  const GoogleSignupRequested({
    required this.idToken,
    required this.email,
    required this.name,
  });
}

// OTP Events
class VerifyOtpRequested extends AuthEvent {
  final String phone;
  final String otpCode;

  const VerifyOtpRequested({required this.phone, required this.otpCode});
}

class ResendOtpRequested extends AuthEvent {
  final String phone;

  const ResendOtpRequested({required this.phone});
}

// Login Events
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String phone;

  const LoginRequested({
    this.email = '',
    required this.password,
    this.phone = '',
  });
}

class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested();
}

// Set Password (after Google registration for new accounts)
class SetPasswordRequested extends AuthEvent {
  final String password;

  const SetPasswordRequested({required this.password});
}

// General Auth Events
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}
