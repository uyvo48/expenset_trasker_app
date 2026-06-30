part of 'auth_bloc.dart';

enum AuthStatus { initial, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthTokens? tokens;
  final bool isSubmitting;
  final bool isRefreshing;
  final bool isChangingPassword;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.tokens,
    this.isSubmitting = false,
    this.isRefreshing = false,
    this.isChangingPassword = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isInitializing => status == AuthStatus.initial;
  bool get isAuthenticated => tokens != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthTokens? tokens,
    bool? isSubmitting,
    bool? isRefreshing,
    bool? isChangingPassword,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      tokens: tokens ?? this.tokens,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
