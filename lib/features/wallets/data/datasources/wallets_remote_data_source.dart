import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/wallet_model.dart';

abstract class WalletsRemoteDataSource {
  Future<List<WalletModel>> getWallets();

  Future<({String message, WalletModel wallet})> createWallet({
    required String name,
    String? description,
  });

  Future<WalletModel> getWalletDetails({required int id});

  Future<String> inviteMember({
    required int walletId,
    required String email,
  });
}

class WalletsRemoteDataSourceImpl implements WalletsRemoteDataSource {
  WalletsRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<List<WalletModel>> getWallets() async {
    try {
      final response = await _dio.get('/api/wallets');

      final responseData = response.data;
      List<dynamic> list;
      if (responseData is Map<String, dynamic>) {
        list = responseData['data'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        list = responseData;
      } else {
        list = [];
      }

      return list.map((item) => WalletModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, WalletModel wallet})> createWallet({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/api/wallets',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      final message = data['message'] as String? ?? 'Tạo ví thành công';
      final walletData = data['data'] as Map<String, dynamic>? ?? {};

      return (
        message: message,
        wallet: WalletModel.fromJson(walletData),
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<WalletModel> getWalletDetails({required int id}) async {
    try {
      final response = await _dio.get('/api/wallets/$id');
      final data = response.data as Map<String, dynamic>? ?? {};
      final walletData = data['data'] as Map<String, dynamic>? ?? data;
      return WalletModel.fromJson(walletData);
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> inviteMember({
    required int walletId,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/api/wallets/$walletId/invite',
        data: {
          'email': email,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      return data['message'] as String? ?? 'Đã mời thành viên thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }
}
