part of 'groups_bloc.dart';

enum GroupsStatus { initial, loading, success, failure }

class GroupsState {
  const GroupsState({
    this.status = GroupsStatus.initial,
    this.groups = const [],
    this.selectedGroup,
    this.bills = const [],
    this.balances = const [],
    this.errorMessage,
    this.successMessage,
    this.isMutating = false,
    this.isBillsLoading = false,
    this.isBalancesLoading = false,
  });

  final GroupsStatus status;
  final List<GroupModel> groups;
  final GroupModel? selectedGroup;
  final List<GroupBillModel> bills;
  final List<GroupBalanceModel> balances;
  final String? errorMessage;
  final String? successMessage;
  final bool isMutating;
  final bool isBillsLoading;
  final bool isBalancesLoading;

  GroupsState copyWith({
    GroupsStatus? status,
    List<GroupModel>? groups,
    GroupModel? selectedGroup,
    List<GroupBillModel>? bills,
    List<GroupBalanceModel>? balances,
    String? errorMessage,
    String? successMessage,
    bool? isMutating,
    bool? isBillsLoading,
    bool? isBalancesLoading,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GroupsState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      bills: bills ?? this.bills,
      balances: balances ?? this.balances,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isMutating: isMutating ?? this.isMutating,
      isBillsLoading: isBillsLoading ?? this.isBillsLoading,
      isBalancesLoading: isBalancesLoading ?? this.isBalancesLoading,
    );
  }
}
