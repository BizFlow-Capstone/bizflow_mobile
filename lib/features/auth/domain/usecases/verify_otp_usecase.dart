import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  Future<AuthResponse> call({required String phone, required String otpCode}) {
    return _repository.verifyOtp(phone: phone, otpCode: otpCode);
  }
}
