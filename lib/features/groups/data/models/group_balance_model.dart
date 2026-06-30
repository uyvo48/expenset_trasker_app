class DebtDetailModel {
  const DebtDetailModel({
    required this.memberId,
    required this.username,
    required this.amount,
  });

  final int memberId;
  final String username;
  final int amount;

  factory DebtDetailModel.fromJson(Map<String, dynamic> json) {
    // API uses 'to_member_id' or 'from_member_id', let's support both
    final mid = json['to_member_id'] as int? ?? json['from_member_id'] as int? ?? 0;
    // API uses 'to_username' or 'from_username', let's support both
    final uname = json['to_username'] as String? ?? json['from_username'] as String? ?? '';

    return DebtDetailModel(
      memberId: mid,
      username: uname.isNotEmpty ? uname : 'Thành viên #$mid',
      amount: _asInt(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'username': username,
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

class GroupBalanceModel {
  const GroupBalanceModel({
    required this.memberId,
    this.userId,
    this.guestName,
    this.username,
    required this.owes,
    required this.getsBack,
  });

  final int memberId;
  final int? userId;
  final String? guestName;
  final String? username;
  final List<DebtDetailModel> owes;
  final List<DebtDetailModel> getsBack;

  factory GroupBalanceModel.fromJson(Map<String, dynamic> json) {
    final owesList = (json['owes'] as List<dynamic>? ?? [])
        .map((o) => DebtDetailModel.fromJson(o as Map<String, dynamic>))
        .toList();

    final getsBackList = (json['gets_back'] as List<dynamic>? ?? [])
        .map((g) => DebtDetailModel.fromJson(g as Map<String, dynamic>))
        .toList();

    return GroupBalanceModel(
      memberId: json['member_id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      guestName: json['guest_name'] as String?,
      username: json['username'] as String?,
      owes: owesList,
      getsBack: getsBackList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'user_id': userId,
      'guest_name': guestName,
      'username': username,
      'owes': owes.map((o) => o.toJson()).toList(),
      'gets_back': getsBack.map((g) => g.toJson()).toList(),
    };
  }

  String get displayName {
    if (guestName != null && guestName!.trim().isNotEmpty) {
      return guestName!;
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!;
    }
    return 'Thành viên #$memberId';
  }
}
