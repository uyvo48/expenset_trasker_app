class BillSplitModel {
  const BillSplitModel({
    required this.id,
    required this.billId,
    required this.groupMemberId,
    required this.amount,
  });

  final int id;
  final int billId;
  final int groupMemberId;
  final int amount;

  factory BillSplitModel.fromJson(Map<String, dynamic> json) {
    return BillSplitModel(
      id: json['id'] as int? ?? 0,
      billId: json['bill_id'] as int? ?? 0,
      groupMemberId: json['group_member_id'] as int? ?? 0,
      amount: _asInt(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'group_member_id': groupMemberId,
      'amount': amount,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class GroupBillModel {
  const GroupBillModel({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.payerMemberId,
    required this.category,
    this.description,
    required this.splitMethod,
    this.splits,
    this.createdAt,
  });

  final int id;
  final int groupId;
  final int amount;
  final int payerMemberId;
  final String category;
  final String? description;
  final String splitMethod; // equal, exact
  final List<BillSplitModel>? splits;
  final DateTime? createdAt;

  factory GroupBillModel.fromJson(Map<String, dynamic> json) {
    List<BillSplitModel>? splitsList;
    if (json['splits'] != null) {
      splitsList = (json['splits'] as List<dynamic>)
          .map((s) => BillSplitModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    DateTime? createdTime;
    if (json['created_at'] != null) {
      createdTime = DateTime.tryParse(json['created_at'] as String)?.toLocal();
    }

    return GroupBillModel(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int? ?? 0,
      amount: _asInt(json['amount']),
      payerMemberId: json['payer_member_id'] as int? ?? 0,
      category: json['category'] as String? ?? 'Food',
      description: json['description'] as String?,
      splitMethod: json['split_method'] as String? ?? 'equal',
      splits: splitsList,
      createdAt: createdTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'amount': amount,
      'payer_member_id': payerMemberId,
      'category': category,
      'description': description,
      'split_method': splitMethod,
      if (splits != null) 'splits': splits!.map((s) => s.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
