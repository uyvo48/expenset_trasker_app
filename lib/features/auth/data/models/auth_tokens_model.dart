import '../../domain/entities/auth_tokens.dart';

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  factory AuthTokensModel.fromEntity(AuthTokens tokens) {
    return AuthTokensModel(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }
}
