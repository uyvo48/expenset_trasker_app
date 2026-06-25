import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<String> register({
    required String email,
    required String password,
  });

  Future<AuthTokens> login({
    required String email,
    required String password,
  });

  Future<String> refreshAccessToken({required String refreshToken});

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<AuthTokens?> getSavedTokens();

  Future<void> saveTokens(AuthTokens tokens);

  Future<void> saveAccessToken(String accessToken);

  Future<void> clearTokens();
}
