// Auth Events - User actions
abstract class AuthEvent {
  const AuthEvent();
}

enum ForgotPasswordChannel { email, phone }

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

class RegisterWithPhoneRequested extends AuthEvent {
  final String phone;
  final String password;
  final String? fullName;

  const RegisterWithPhoneRequested({
    required this.phone,
    required this.password,
    this.fullName,
  });
}

class PhoneOtpCodeSubmitted extends AuthEvent {
  final String smsCode;

  const PhoneOtpCodeSubmitted({required this.smsCode});
}

class ResendPhoneOtpRequested extends AuthEvent {
  const ResendPhoneOtpRequested();
}

class CancelPhoneRegisterFlowRequested extends AuthEvent {
  const CancelPhoneRegisterFlowRequested();
}

class LoadCredentialsRequested extends AuthEvent {
  const LoadCredentialsRequested();
}

class LinkEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const LinkEmailRequested({required this.email, required this.password});
}

class LinkGoogleRequested extends AuthEvent {
  const LinkGoogleRequested();
}

class StartLinkPhoneRequested extends AuthEvent {
  final String phone;
  final String? password;

  const StartLinkPhoneRequested({required this.phone, this.password});
}

class SubmitLinkPhoneOtpRequested extends AuthEvent {
  final String smsCode;

  const SubmitLinkPhoneOtpRequested({required this.smsCode});
}

class ResendLinkPhoneOtpRequested extends AuthEvent {
  const ResendLinkPhoneOtpRequested();
}

// Set Password (after Google registration for new accounts)
class SetPasswordRequested extends AuthEvent {
  final String password;

  const SetPasswordRequested({required this.password});
}

class ForgotPasswordSendOtpRequested extends AuthEvent {
  final String identifier;
  final ForgotPasswordChannel channel;

  const ForgotPasswordSendOtpRequested({
    required this.identifier,
    required this.channel,
  });
}

class ForgotPasswordVerifyOtpRequested extends AuthEvent {
  final String identifier;
  final String otpCode;
  final ForgotPasswordChannel channel;

  const ForgotPasswordVerifyOtpRequested({
    required this.identifier,
    required this.otpCode,
    required this.channel,
  });
}

class ForgotPasswordResetRequested extends AuthEvent {
  final String password;

  const ForgotPasswordResetRequested({required this.password});
}

class LoadProfileRequested extends AuthEvent {
  const LoadProfileRequested();
}

class UpdateProfileRequested extends AuthEvent {
  final String? fullName;
  final String? taxCode;

  const UpdateProfileRequested({this.fullName, this.taxCode});
}

class UpdateAvatarRequested extends AuthEvent {
  final String avatarPath;

  const UpdateAvatarRequested({required this.avatarPath});
}

class RemoveAvatarRequested extends AuthEvent {
  const RemoveAvatarRequested();
}

class ChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });
}

class DeleteAccountRequested extends AuthEvent {
  final String password;

  const DeleteAccountRequested({required this.password});
}

// General Auth Events
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}

class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}
