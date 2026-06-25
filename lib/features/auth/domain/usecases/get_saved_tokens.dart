import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class GetSavedTokens {
  const GetSavedTokens(this._repository);

  final AuthRepository _repository;

  Future<AuthTokens?> call() {
    return _repository.getSavedTokens();
  }
}
