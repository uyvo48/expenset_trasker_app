import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/goal_model.dart';

abstract class GoalsRemoteDataSource {
  Future<List<GoalModel>> getGoals();

  Future<({String message, GoalModel goal})> createGoal({
    required String name,
    required int targetAmount,
    DateTime? deadline,
    required String category,
    bool autoAllocate,
    int? allocatePercent,
  });

  Future<GoalModel> getGoalDetails(int id);

  Future<({String message, GoalModel goal})> updateGoal({
    required int id,
    required String name,
    required int targetAmount,
    DateTime? deadline,
    required String category,
    bool autoAllocate,
    int? allocatePercent,
  });

  Future<String> deleteGoal(int id);

  Future<({String message, GoalModel goal, int allocatedAmount, int walletBalance})> allocateMoney({
    required int id,
    required int amount,
  });

  Future<({String message, GoalModel goal})> withdrawMoney({
    required int id,
    required int amount,
  });
}

class GoalsRemoteDataSourceImpl implements GoalsRemoteDataSource {
  GoalsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<List<GoalModel>> getGoals() async {
    try {
      final response = await _dio.get('/api/goals');
      final data = response.data as Map<String, dynamic>? ?? {};
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((item) => GoalModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, GoalModel goal})> createGoal({
    required String name,
    required int targetAmount,
    DateTime? deadline,
    required String category,
    bool autoAllocate = false,
    int? allocatePercent,
  }) async {
    try {
      final response = await _dio.post(
        '/api/goals',
        data: {
          'name': name,
          'target_amount': targetAmount,
          if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
          'category': category,
          'auto_allocate': autoAllocate,
          if (autoAllocate && allocatePercent != null) 'allocate_percent': allocatePercent,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      final message = data['message'] as String? ?? 'Tạo mục tiêu thành công';
      final goalData = data['data'] as Map<String, dynamic>? ?? {};

      return (
        message: message,
        goal: GoalModel.fromJson(goalData),
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<GoalModel> getGoalDetails(int id) async {
    try {
      final response = await _dio.get('/api/goals/$id');
      final data = response.data as Map<String, dynamic>? ?? {};
      final goalData = data['data'] as Map<String, dynamic>? ?? data;
      return GoalModel.fromJson(goalData);
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, GoalModel goal})> updateGoal({
    required int id,
    required String name,
    required int targetAmount,
    DateTime? deadline,
    required String category,
    bool autoAllocate = false,
    int? allocatePercent,
  }) async {
    try {
      final response = await _dio.put(
        '/api/goals/$id',
        data: {
          'name': name,
          'target_amount': targetAmount,
          if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
          'category': category,
          'auto_allocate': autoAllocate,
          if (autoAllocate && allocatePercent != null) 'allocate_percent': allocatePercent,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      final message = data['message'] as String? ?? 'Cập nhật mục tiêu thành công';
      final goalData = data['data'] as Map<String, dynamic>? ?? {};

      return (
        message: message,
        goal: GoalModel.fromJson(goalData),
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> deleteGoal(int id) async {
    try {
      final response = await _dio.delete('/api/goals/$id');
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['message'] as String? ?? 'Xóa mục tiêu thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, GoalModel goal, int allocatedAmount, int walletBalance})> allocateMoney({
    required int id,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        '/api/goals/$id/allocate',
        data: {
          'amount': amount,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      final message = data['message'] as String? ?? 'Phân bổ tiền vào mục tiêu thành công';
      final goalData = data['data'] as Map<String, dynamic>? ?? {};

      return (
        message: message,
        goal: GoalModel.fromJson(goalData),
        allocatedAmount: goalData['allocated_amount'] as int? ?? amount,
        walletBalance: goalData['wallet_balance'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, GoalModel goal})> withdrawMoney({
    required int id,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        '/api/goals/$id/withdraw',
        data: {
          'amount': amount,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      final message = data['message'] as String? ?? 'Rút tiền thành công';
      final goalData = data['data'] as Map<String, dynamic>? ?? {};

      return (
        message: message,
        goal: GoalModel.fromJson(goalData),
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }
}
