part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class AuthInitializeRequested extends AuthEvent {
  const AuthInitializeRequested();
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
  });
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });
}

class AuthRefreshAccessTokenRequested extends AuthEvent {
  const AuthRefreshAccessTokenRequested();
}

class AuthChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const AuthChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthClearMessageRequested extends AuthEvent {
  const AuthClearMessageRequested();
}
