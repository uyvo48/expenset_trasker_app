import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();

  Future<({String message, UserProfileModel profile})> updateProfile({
    required String username,
    required String email,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await _dio.get('/api/profile');

      return UserProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, UserProfileModel profile})> updateProfile({
    required String username,
    required String email,
  }) async {
    try {
      final response = await _dio.put(
        '/api/profile',
        data: {
          'username': username,
          'email': email,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return (
        message: data['message'] as String? ?? 'Cập nhật hồ sơ thành công',
        profile: UserProfileModel.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        ),
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }
}
