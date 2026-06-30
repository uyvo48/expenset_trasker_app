import 'package:flutter_bloc/flutter_bloc.dart';

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

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
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
        _changePassword = changePassword,
        super(const AuthState()) {
    on<AuthInitializeRequested>(_onInitializeRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRefreshAccessTokenRequested>(_onRefreshAccessTokenRequested);
    on<AuthChangePasswordRequested>(_onChangePasswordRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthClearMessageRequested>(_onClearMessageRequested);
  }

  final GetSavedTokens _getSavedTokens;
  final SaveTokens _saveTokens;
  final SaveAccessToken _saveAccessToken;
  final ClearTokens _clearTokens;
  final RegisterUser _registerUser;
  final LoginUser _loginUser;
  final RefreshAccessToken _refreshAccessToken;
  final ChangePassword _changePassword;

  Future<void> _onInitializeRequested(
    AuthInitializeRequested event,
    Emitter<AuthState> emit,
  ) async {
    final tokens = await _getSavedTokens();
    if (tokens != null) {
      emit(AuthState(
        status: AuthStatus.authenticated,
        tokens: tokens,
      ));
    } else {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      final message = await _registerUser(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        isSubmitting: false,
        successMessage: message,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      final tokens = await _loginUser(
        email: event.email,
        password: event.password,
      );
      await _saveTokens(tokens);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        tokens: tokens,
        isSubmitting: false,
        successMessage: 'Đăng nhập thành công',
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onRefreshAccessTokenRequested(
    AuthRefreshAccessTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentTokens = state.tokens;
    if (currentTokens == null) {
      emit(state.copyWith(errorMessage: 'Phiên đăng nhập không hợp lệ'));
      return;
    }

    emit(state.copyWith(
      isRefreshing: true,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      final accessToken = await _refreshAccessToken(
        refreshToken: currentTokens.refreshToken,
      );
      await _saveAccessToken(accessToken);
      final updatedTokens = currentTokens.copyWith(accessToken: accessToken);
      emit(state.copyWith(
        isRefreshing: false,
        tokens: updatedTokens,
        successMessage: 'Làm mới token thành công',
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isChangingPassword: true,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      final message = await _changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(
        isChangingPassword: false,
        successMessage: message,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isChangingPassword: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isChangingPassword: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _clearTokens();
    emit(const AuthState(
      status: AuthStatus.unauthenticated,
    ));
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _clearTokens();
    emit(const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    ));
  }

  void _onClearMessageRequested(
    AuthClearMessageRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}
