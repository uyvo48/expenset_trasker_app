import '../repositories/auth_repository.dart';

class ClearTokens {
  const ClearTokens(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.clearTokens();
  }
}
