import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/change_password.dart';
import 'features/auth/domain/usecases/clear_tokens.dart';
import 'features/auth/domain/usecases/get_saved_tokens.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/refresh_access_token.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/domain/usecases/save_access_token.dart';
import 'features/auth/domain/usecases/save_tokens.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/auth_gate.dart';

void main() {
  late final AuthBloc authBloc;

  // Khởi tạo Dio singleton trước khi build AuthBloc và truyền callback khi hết hạn session
  DioClient.initialize(
    onSessionExpired: () {
      authBloc.add(const AuthSessionExpired());
    },
  );

  authBloc = _buildAuthBloc();

  runApp(ExpenseTrackerApp(authBloc: authBloc));
}

AuthBloc _buildAuthBloc() {
  final AuthRepository repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    localDataSource: AuthLocalDataSourceImpl(),
  );

  return AuthBloc(
    getSavedTokens: GetSavedTokens(repository),
    saveTokens: SaveTokens(repository),
    saveAccessToken: SaveAccessToken(repository),
    clearTokens: ClearTokens(repository),
    registerUser: RegisterUser(repository),
    loginUser: LoginUser(repository),
    refreshAccessToken: RefreshAccessToken(repository),
    changePassword: ChangePassword(repository),
  )..add(const AuthInitializeRequested());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({
    super.key,
    required this.authBloc,
  });

  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
