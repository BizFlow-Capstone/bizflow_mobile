import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';

class ResendOtpUseCase {
  final AuthRepository _repository;

  ResendOtpUseCase(this._repository);

  Future<AuthResponse> call({required String phone}) {
    return _repository.resendOtp(phone: phone);
  }
}
