import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_tokens_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> register({
    required String email,
    required String password,
  });

  Future<AuthTokensModel> login({
    required String email,
    required String password,
  });

  Future<String> refreshAccessToken({required String refreshToken});

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({Dio? publicDio, Dio? authDio})
      : _publicDio = publicDio ?? DioClient.publicInstance,
        _authDio = authDio ?? DioClient.instance;

  /// Dio không có AuthInterceptor — dùng cho register, login, refresh.
  final Dio _publicDio;

  /// Dio chính có AuthInterceptor — dùng cho changePassword.
  final Dio _authDio;

  @override
  Future<String> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _publicDio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      return response.data['message'] as String? ?? 'Đăng ký thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _publicDio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return AuthTokensModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> refreshAccessToken({required String refreshToken}) async {
    try {
      final response = await _publicDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      return response.data['access_token'] as String;
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _authDio.put(
        '/api/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      return response.data['message'] as String? ?? 'Đổi mật khẩu thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }
}
