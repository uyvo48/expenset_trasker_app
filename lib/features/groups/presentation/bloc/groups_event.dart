part of 'groups_bloc.dart';

abstract class GroupsEvent {
  const GroupsEvent();
}

class GroupsLoadRequested extends GroupsEvent {
  const GroupsLoadRequested();
}

class GroupCreateRequested extends GroupsEvent {
  const GroupCreateRequested({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}

class GroupSelectRequested extends GroupsEvent {
  const GroupSelectRequested(this.groupId);

  final int groupId;
}

class GroupAddMemberRequested extends GroupsEvent {
  const GroupAddMemberRequested({
    required this.groupId,
    this.email,
    this.guestName,
  });

  final int groupId;
  final String? email;
  final String? guestName;
}

class GroupDeleteMemberRequested extends GroupsEvent {
  const GroupDeleteMemberRequested({
    required this.groupId,
    required this.memberId,
  });

  final int groupId;
  final int memberId;
}

class GroupBillsLoadRequested extends GroupsEvent {
  const GroupBillsLoadRequested(this.groupId);

  final int groupId;
}

class GroupBillCreateRequested extends GroupsEvent {
  const GroupBillCreateRequested({
    required this.groupId,
    required this.amount,
    required this.payerMemberId,
    required this.category,
    this.description,
    required this.splitMethod,
    required this.splits,
  });

  final int groupId;
  final int amount;
  final int payerMemberId;
  final String category;
  final String? description;
  final String splitMethod;
  final List<Map<String, dynamic>> splits;
}

class GroupBalancesLoadRequested extends GroupsEvent {
  const GroupBalancesLoadRequested(this.groupId);

  final int groupId;
}

class GroupDebtSettleRequested extends GroupsEvent {
  const GroupDebtSettleRequested({
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });

  final int groupId;
  final int fromMemberId;
  final int toMemberId;
  final int amount;
}

class GroupsClearMessageRequested extends GroupsEvent {
  const GroupsClearMessageRequested();
}
