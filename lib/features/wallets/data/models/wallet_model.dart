class WalletMemberModel {
  const WalletMemberModel({
    required this.id,
    required this.username,
    required this.email,
  });

  final int id;
  final String username;
  final String email;

  factory WalletMemberModel.fromJson(Map<String, dynamic> json) {
    return WalletMemberModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    this.description,
    required this.balance,
    required this.createdBy,
    this.members,
  });

  final int id;
  final String name;
  final String? description;
  final int balance;
  final int createdBy;
  final List<WalletMemberModel>? members;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    List<WalletMemberModel>? membersList;
    if (json['members'] != null) {
      membersList = (json['members'] as List<dynamic>)
          .map((m) => WalletMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return WalletModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      balance: _asInt(json['balance']),
      createdBy: json['created_by'] as int? ?? 0,
      members: membersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'balance': balance,
      'created_by': createdBy,
      if (members != null) 'members': members!.map((m) => m.toJson()).toList(),
    };
  }

  WalletModel copyWith({
    int? id,
    String? name,
    String? description,
    int? balance,
    int? createdBy,
    List<WalletMemberModel>? members,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
