import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/group_balance_model.dart';
import '../models/group_bill_model.dart';
import '../models/group_model.dart';

abstract class GroupsRemoteDataSource {
  Future<List<GroupModel>> getGroups();

  Future<({String message, GroupModel group})> createGroup({
    required String name,
    String? description,
  });

  Future<GroupModel> getGroupDetails(int id);

  Future<String> addMember({
    required int groupId,
    String? email,
    String? guestName,
  });

  Future<String> deleteMember({
    required int groupId,
    required int memberId,
  });

  Future<List<GroupBillModel>> getGroupBills(int groupId);

  Future<String> createGroupBill({
    required int groupId,
    required int amount,
    required int payerMemberId,
    required String category,
    String? description,
    required String splitMethod,
    required List<Map<String, dynamic>> splits,
  });

  Future<List<GroupBalanceModel>> getGroupBalances(int groupId);

  Future<String> settleDebt({
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required int amount,
  });
}

class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  GroupsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<List<GroupModel>> getGroups() async {
    try {
      final response = await _dio.get('/api/groups');
      final responseData = response.data;
      List<dynamic> list;
      if (responseData is Map<String, dynamic>) {
        list = responseData['data'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        list = responseData;
      } else {
        list = [];
      }
      return list.map((item) => GroupModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<({String message, GroupModel group})> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/api/groups',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      final message = data['message'] as String? ?? 'Tạo nhóm thành công';
      final groupData = data['data'] as Map<String, dynamic>? ?? {};

      return (
        message: message,
        group: GroupModel.fromJson(groupData),
      );
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<GroupModel> getGroupDetails(int id) async {
    try {
      final response = await _dio.get('/api/groups/$id');
      final data = response.data as Map<String, dynamic>? ?? {};

      // API returns: {data: {group: {...}, members: [...]}}
      // or fallback flat format: {id: ..., name: ..., members: [...]}
      final inner = data['data'] as Map<String, dynamic>? ?? data;
      final groupMap = inner['group'] as Map<String, dynamic>? ?? inner;
      final membersList = inner['members'];

      // Merge group fields with members into a single map for GroupModel
      final mergedData = <String, dynamic>{
        ...groupMap,
        if (membersList != null) 'members': membersList,
      };

      return GroupModel.fromJson(mergedData);
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> addMember({
    required int groupId,
    String? email,
    String? guestName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/groups/$groupId/members',
        data: {
          if (email != null && email.isNotEmpty) 'email': email,
          if (guestName != null && guestName.isNotEmpty) 'guest_name': guestName,
        },
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['message'] as String? ?? 'Thêm thành viên thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> deleteMember({
    required int groupId,
    required int memberId,
  }) async {
    try {
      final response = await _dio.delete('/api/groups/$groupId/members/$memberId');
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['message'] as String? ?? 'Xóa thành viên thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<List<GroupBillModel>> getGroupBills(int groupId) async {
    try {
      final response = await _dio.get('/api/groups/$groupId/bills');
      final responseData = response.data;
      List<dynamic> list;
      if (responseData is Map<String, dynamic>) {
        list = responseData['data'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        list = responseData;
      } else {
        list = [];
      }
      return list.map((item) => GroupBillModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> createGroupBill({
    required int groupId,
    required int amount,
    required int payerMemberId,
    required String category,
    String? description,
    required String splitMethod,
    required List<Map<String, dynamic>> splits,
  }) async {
    try {
      final response = await _dio.post(
        '/api/groups/$groupId/bills',
        data: {
          'amount': amount,
          // Try both field names since the backend Go struct may use either
          'payer_id': payerMemberId,
          'payer_member_id': payerMemberId,
          // Backend oneof validation likely uses lowercase category values
          'category': category.toLowerCase(),
          if (description != null) 'description': description,
          'split_method': splitMethod,
          'splits': splits,
        },
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['message'] as String? ?? 'Tạo hóa đơn thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<List<GroupBalanceModel>> getGroupBalances(int groupId) async {
    try {
      final response = await _dio.get('/api/groups/$groupId/balances');
      final data = response.data as Map<String, dynamic>? ?? {};
      final list = data['balances'] as List<dynamic>? ?? [];
      return list.map((item) => GroupBalanceModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }

  @override
  Future<String> settleDebt({
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        '/api/groups/$groupId/settle',
        data: {
          'from_member_id': fromMemberId,
          'to_member_id': toMemberId,
          'amount': amount,
        },
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['message'] as String? ?? 'Xác nhận trả nợ thành công';
    } on DioException catch (e) {
      throw appExceptionFromDioError(e);
    }
  }
}
