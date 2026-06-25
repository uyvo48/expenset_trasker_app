import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transaction_model.dart';

abstract class TransactionsRemoteDataSource {
  Future<List<TransactionModel>> getTransactions({int? walletId});

  Future<List<TransactionModel>> searchTransactions({
    required TransactionSearchFilter filter,
  });

  Future<({String message, TransactionModel transaction})> createTransaction({
    required TransactionPayload payload,
  });

  Future<({String message, TransactionModel transaction})> updateTransaction({
    required int id,
    required TransactionPayload payload,
  });

  Future<String> deleteTransaction({required int id});
}

class TransactionsRemoteDataSourceImpl implements TransactionsRemoteDataSource {
  TransactionsRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<List<TransactionModel>> getTransactions({int? walletId}) async {
    try {
      final response = await _dio.get(
        '/api/transactions',
        queryParameters: {
          if (walletId != null) 'wallet_id': walletId,
        },
      );

      final responseData = response.data;
      List<dynamic> list;
      if (responseData is Map<String, dynamic>) {
        list = responseData['data'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        list = responseData;
      } else {
        list = [];
      }

      return _parseTransactionList(list);
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<List<TransactionModel>> searchTransactions({
    required TransactionSearchFilter filter,
  }) async {
    try {
      final response = await _dio.get(
        '/api/transactions/search',
        queryParameters: filter.toQueryParameters(),
      );

      final data = _asMap(response.data) ?? {};
      return _parseTransactionList(data['data'] as List<dynamic>? ?? []);
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, TransactionModel transaction})> createTransaction({
    required TransactionPayload payload,
  }) async {
    try {
      final response = await _dio.post(
        '/api/transactions',
        data: payload.toJson(),
      );

      return _parseMutationResponse(
        _asMap(response.data),
        'Đã thêm giao dịch thành công',
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, TransactionModel transaction})> updateTransaction({
    required int id,
    required TransactionPayload payload,
  }) async {
    try {
      final response = await _dio.put(
        '/api/transactions/$id',
        data: payload.toJson(),
      );

      return _parseMutationResponse(
        _asMap(response.data),
        'Cập nhật giao dịch thành công',
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> deleteTransaction({required int id}) async {
    try {
      final response = await _dio.delete('/api/transactions/$id');

      final data = _asMap(response.data);
      return data?['message'] as String? ?? 'Xóa giao dịch thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  List<TransactionModel> _parseTransactionList(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList();
  }

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  ({String message, TransactionModel transaction}) _parseMutationResponse(
    Map<String, dynamic>? data,
    String fallbackMessage,
  ) {
    final responseData = data ?? {};
    return (
      message: responseData['message'] as String? ?? fallbackMessage,
      transaction: TransactionModel.fromJson(
        responseData['data'] as Map<String, dynamic>? ?? responseData,
      ),
    );
  }
}
