// Auth States - UI states
abstract class AuthState {
  const AuthState();
}

// Initial State
class AuthInitial extends AuthState {
  const AuthInitial();
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
  final String message;

  const SignupFailure({required this.message});
}

// OTP Verification States
class OtpVerificationInProgress extends AuthState {
  const OtpVerificationInProgress();
}

class OtpVerificationSuccess extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  const OtpVerificationSuccess({
    required this.token,
    required this.user,
  });
}

class OtpVerificationFailure extends AuthState {
  final String message;

  const OtpVerificationFailure({required this.message});
}

// Login States
class LoginInProgress extends AuthState {
  const LoginInProgress();
}

class LoginSuccess extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  const LoginSuccess({
    required this.token,
    required this.user,
  });
}

class LoginFailure extends AuthState {
  final String message;

  const LoginFailure({required this.message});
}

// Authenticated State
class AuthAuthenticated extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  const AuthAuthenticated({
    required this.token,
    required this.user,
  });
}

// Unauthenticated State
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// Error State
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});
}
