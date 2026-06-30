class GroupMemberModel {
  const GroupMemberModel({
    required this.id,
    required this.groupId,
    this.userId,
    this.guestName,
    required this.role,
  });

  final int id;
  final int groupId;
  final int? userId;
  final String? guestName;
  final String role; // admin, member

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      guestName: json['guest_name'] as String?,
      role: json['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'guest_name': guestName,
      'role': role,
    };
  }

  String get displayName {
    if (guestName != null && guestName!.trim().isNotEmpty) {
      return guestName!;
    }
    return 'Thành viên #$id';
  }
}

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.members,
  });

  final int id;
  final String name;
  final String? description;
  final int createdBy;
  final List<GroupMemberModel>? members;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    List<GroupMemberModel>? membersList;
    if (json['members'] != null) {
      membersList = (json['members'] as List<dynamic>)
          .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return GroupModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdBy: json['created_by'] as int? ?? 0,
      members: membersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      if (members != null) 'members': members!.map((m) => m.toJson()).toList(),
    };
  }

  GroupModel copyWith({
    int? id,
    String? name,
    String? description,
    int? createdBy,
    List<GroupMemberModel>? members,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
    );
  }
}
