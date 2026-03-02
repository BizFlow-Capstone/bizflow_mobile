import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<AuthResponse> call({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    return _repository.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );
  }
}
