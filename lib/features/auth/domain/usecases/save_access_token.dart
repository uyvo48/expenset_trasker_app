import '../repositories/auth_repository.dart';

class SaveAccessToken {
  const SaveAccessToken(this._repository);

  final AuthRepository _repository;

  Future<void> call(String accessToken) {
    return _repository.saveAccessToken(accessToken);
  }
}
