import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_tokens_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<String> register({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.register(email: email, password: password);
  }

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<String> refreshAccessToken({required String refreshToken}) {
    return _remoteDataSource.refreshAccessToken(refreshToken: refreshToken);
  }

  @override
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<AuthTokens?> getSavedTokens() {
    return _localDataSource.getTokens();
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) {
    return _localDataSource.saveTokens(AuthTokensModel.fromEntity(tokens));
  }

  @override
  Future<void> saveAccessToken(String accessToken) {
    return _localDataSource.saveAccessToken(accessToken);
  }

  @override
  Future<void> clearTokens() {
    return _localDataSource.clearTokens();
  }
}
