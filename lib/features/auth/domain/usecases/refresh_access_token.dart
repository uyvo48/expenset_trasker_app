import '../repositories/auth_repository.dart';

class RefreshAccessToken {
  const RefreshAccessToken(this._repository);

  final AuthRepository _repository;

  Future<String> call({required String refreshToken}) {
    return _repository.refreshAccessToken(refreshToken: refreshToken);
  }
}
