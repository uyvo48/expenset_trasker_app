import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expenset_tracker/core/network/dio_client.dart';
import 'package:expenset_tracker/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:expenset_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expenset_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expenset_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/change_password.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/clear_tokens.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/get_saved_tokens.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/login_user.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/refresh_access_token.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/register_user.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/save_access_token.dart';
import 'package:expenset_tracker/features/auth/domain/usecases/save_tokens.dart';
import 'package:expenset_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:expenset_tracker/main.dart';

void main() {
  testWidgets('shows login form when no session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    DioClient.initialize();

    await tester.pumpWidget(ExpenseTrackerApp(controller: _buildController()));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}

AuthController _buildController([AuthRepository? repository]) {
  repository ??= AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    localDataSource: AuthLocalDataSourceImpl(),
  );

  return AuthController(
    getSavedTokens: GetSavedTokens(repository),
    saveTokens: SaveTokens(repository),
    saveAccessToken: SaveAccessToken(repository),
    clearTokens: ClearTokens(repository),
    registerUser: RegisterUser(repository),
    loginUser: LoginUser(repository),
    refreshAccessToken: RefreshAccessToken(repository),
    changePassword: ChangePassword(repository),
  );
}
