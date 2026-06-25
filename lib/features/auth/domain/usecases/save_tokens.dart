import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class SaveTokens {
  const SaveTokens(this._repository);

  final AuthRepository _repository;

  Future<void> call(AuthTokens tokens) {
    return _repository.saveTokens(tokens);
  }
}
