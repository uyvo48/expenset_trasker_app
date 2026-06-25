import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_tokens_model.dart';

abstract class AuthLocalDataSource {
  Future<AuthTokensModel?> getTokens();

  Future<void> saveTokens(AuthTokensModel tokens);

  Future<void> saveAccessToken(String accessToken);

  Future<void> clearTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<AuthTokensModel?> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> saveTokens(AuthTokensModel tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    await prefs.setString(_refreshTokenKey, tokens.refreshToken);
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
