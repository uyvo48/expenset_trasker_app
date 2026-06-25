import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/clear_tokens.dart';
import '../../domain/usecases/get_saved_tokens.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/refresh_access_token.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/save_access_token.dart';
import '../../domain/usecases/save_tokens.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required GetSavedTokens getSavedTokens,
    required SaveTokens saveTokens,
    required SaveAccessToken saveAccessToken,
    required ClearTokens clearTokens,
    required RegisterUser registerUser,
    required LoginUser loginUser,
    required RefreshAccessToken refreshAccessToken,
    required ChangePassword changePassword,
  })  : _getSavedTokens = getSavedTokens,
        _saveTokens = saveTokens,
        _saveAccessToken = saveAccessToken,
        _clearTokens = clearTokens,
        _registerUser = registerUser,
        _loginUser = loginUser,
        _refreshAccessToken = refreshAccessToken,
        _changePassword = changePassword;

  final GetSavedTokens _getSavedTokens;
  final SaveTokens _saveTokens;
  final SaveAccessToken _saveAccessToken;
  final ClearTokens _clearTokens;
  final RegisterUser _registerUser;
  final LoginUser _loginUser;
  final RefreshAccessToken _refreshAccessToken;
  final ChangePassword _changePassword;

  AuthTokens? _tokens;
  bool _isInitializing = true;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  bool _isChangingPassword = false;

  AuthTokens? get tokens => _tokens;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _tokens != null;
  bool get isSubmitting => _isSubmitting;
  bool get isRefreshing => _isRefreshing;
  bool get isChangingPassword => _isChangingPassword;

  Future<void> initialize() async {
    _tokens = await _getSavedTokens();
    _isInitializing = false;
    notifyListeners();
  }

  Future<String> register({
    required String email,
    required String password,
  }) async {
    return _guardSubmitting(() {
      return _registerUser(email: email, password: password);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _guardSubmitting(() async {
      final tokens = await _loginUser(email: email, password: password);
      await _saveTokens(tokens);
      _tokens = tokens;
    });
  }

  /// Làm mới access token thủ công (dùng cho nút UI).
  Future<String> refreshAccessToken() async {
    final currentTokens = _tokens;
    if (currentTokens == null) {
      throw const AppException('Phiên đăng nhập không hợp lệ');
    }

    _isRefreshing = true;
    notifyListeners();
    try {
      final accessToken = await _refreshAccessToken(
        refreshToken: currentTokens.refreshToken,
      );
      await _saveAccessToken(accessToken);
      _tokens = currentTokens.copyWith(accessToken: accessToken);
      return 'Làm mới token thành công';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Đổi mật khẩu — Dio interceptor tự gắn token.
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isChangingPassword = true;
    notifyListeners();
    try {
      return await _changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clearTokens();
    _tokens = null;
    notifyListeners();
  }

  Future<T> _guardSubmitting<T>(Future<T> Function() action) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
