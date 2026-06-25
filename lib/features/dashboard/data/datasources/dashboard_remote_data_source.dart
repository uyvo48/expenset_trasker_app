import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_analytics_model.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> getDashboard();

  Future<List<CategoryAnalyticsModel>> getCategoryAnalytics();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<DashboardSummaryModel> getDashboard() async {
    try {
      final response = await _dio.get('/api/dashboard');

      return DashboardSummaryModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<List<CategoryAnalyticsModel>> getCategoryAnalytics() async {
    try {
      final response = await _dio.get('/api/analytics/categories');

      final responseData = response.data;
      List<dynamic> list;
      if (responseData is Map<String, dynamic>) {
        list = responseData['data'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        list = responseData;
      } else {
        list = [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(CategoryAnalyticsModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }
}
