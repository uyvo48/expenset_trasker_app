import '../repositories/auth_repository.dart';

class ChangePassword {
  const ChangePassword(this._repository);

  final AuthRepository _repository;

  Future<String> call({
    required String oldPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
