import '../repositories/auth_repository.dart';

class RegisterUser {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  Future<String> call({
    required String email,
    required String password,
  }) {
    return _repository.register(email: email, password: password);
  }
}
