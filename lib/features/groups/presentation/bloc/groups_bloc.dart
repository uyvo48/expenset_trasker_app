import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/groups_remote_data_source.dart';
import '../../data/models/group_balance_model.dart';
import '../../data/models/group_bill_model.dart';
import '../../data/models/group_model.dart';

part 'groups_event.dart';
part 'groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  GroupsBloc({
    GroupsRemoteDataSource? groupsRemoteDataSource,
  })  : _groupsRemoteDataSource =
            groupsRemoteDataSource ?? GroupsRemoteDataSourceImpl(),
        super(const GroupsState()) {
    on<GroupsLoadRequested>(_onLoadRequested);
    on<GroupCreateRequested>(_onCreateRequested);
    on<GroupSelectRequested>(_onSelectRequested);
    on<GroupAddMemberRequested>(_onAddMemberRequested);
    on<GroupDeleteMemberRequested>(_onDeleteMemberRequested);
    on<GroupBillsLoadRequested>(_onBillsLoadRequested);
    on<GroupBillCreateRequested>(_onBillCreateRequested);
    on<GroupBalancesLoadRequested>(_onBalancesLoadRequested);
    on<GroupDebtSettleRequested>(_onDebtSettleRequested);
    on<GroupsClearMessageRequested>(_onClearMessageRequested);
  }

  final GroupsRemoteDataSource _groupsRemoteDataSource;

  Future<void> _onLoadRequested(
    GroupsLoadRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupsLoadRequested start');
    emit(state.copyWith(
      status: GroupsStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final groups = await _groupsRemoteDataSource.getGroups();
      emit(state.copyWith(
        status: GroupsStatus.success,
        groups: groups,
      ));
      AppLogger.info('[GroupsBloc] GroupsLoadRequested done groupsCount=${groups.length}');
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupsLoadRequested AppException', error: error);
      emit(state.copyWith(
        status: GroupsStatus.failure,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupsLoadRequested unexpected error', error: error);
      emit(state.copyWith(
        status: GroupsStatus.failure,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onCreateRequested(
    GroupCreateRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupCreateRequested name=${event.name}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _groupsRemoteDataSource.createGroup(
        name: event.name,
        description: event.description,
      );

      final updatedGroups = List<GroupModel>.from(state.groups)..add(result.group);

      emit(state.copyWith(
        isMutating: false,
        groups: updatedGroups,
        successMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupCreateRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupCreateRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onSelectRequested(
    GroupSelectRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupSelectRequested groupId=${event.groupId}');
    emit(state.copyWith(
      status: GroupsStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final details = await _groupsRemoteDataSource.getGroupDetails(event.groupId);
      emit(state.copyWith(
        status: GroupsStatus.success,
        selectedGroup: details,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupSelectRequested AppException', error: error);
      emit(state.copyWith(
        status: GroupsStatus.failure,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupSelectRequested unexpected error', error: error);
      emit(state.copyWith(
        status: GroupsStatus.failure,
        errorMessage: 'Không thể tải chi tiết nhóm',
      ));
    }
  }

  Future<void> _onAddMemberRequested(
    GroupAddMemberRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupAddMemberRequested groupId=${event.groupId}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _groupsRemoteDataSource.addMember(
        groupId: event.groupId,
        email: event.email,
        guestName: event.guestName,
      );

      // Re-fetch details to update member list
      final updatedDetails = await _groupsRemoteDataSource.getGroupDetails(event.groupId);

      emit(state.copyWith(
        isMutating: false,
        selectedGroup: updatedDetails,
        successMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupAddMemberRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupAddMemberRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onDeleteMemberRequested(
    GroupDeleteMemberRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupDeleteMemberRequested groupId=${event.groupId} memberId=${event.memberId}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _groupsRemoteDataSource.deleteMember(
        groupId: event.groupId,
        memberId: event.memberId,
      );

      // Re-fetch details to update member list
      final updatedDetails = await _groupsRemoteDataSource.getGroupDetails(event.groupId);

      emit(state.copyWith(
        isMutating: false,
        selectedGroup: updatedDetails,
        successMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupDeleteMemberRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupDeleteMemberRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onBillsLoadRequested(
    GroupBillsLoadRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupBillsLoadRequested groupId=${event.groupId}');
    emit(state.copyWith(
      isBillsLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final bills = await _groupsRemoteDataSource.getGroupBills(event.groupId);
      emit(state.copyWith(
        isBillsLoading: false,
        bills: bills,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupBillsLoadRequested AppException', error: error);
      emit(state.copyWith(
        isBillsLoading: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupBillsLoadRequested unexpected error', error: error);
      emit(state.copyWith(
        isBillsLoading: false,
        errorMessage: 'Không thể tải hóa đơn',
      ));
    }
  }

  Future<void> _onBillCreateRequested(
    GroupBillCreateRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupBillCreateRequested amount=${event.amount}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _groupsRemoteDataSource.createGroupBill(
        groupId: event.groupId,
        amount: event.amount,
        payerMemberId: event.payerMemberId,
        category: event.category,
        description: event.description,
        splitMethod: event.splitMethod,
        splits: event.splits,
      );

      // Re-fetch bills and balances
      final bills = await _groupsRemoteDataSource.getGroupBills(event.groupId);
      final balances = await _groupsRemoteDataSource.getGroupBalances(event.groupId);

      emit(state.copyWith(
        isMutating: false,
        bills: bills,
        balances: balances,
        successMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupBillCreateRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupBillCreateRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onBalancesLoadRequested(
    GroupBalancesLoadRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupBalancesLoadRequested groupId=${event.groupId}');
    emit(state.copyWith(
      isBalancesLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final balances = await _groupsRemoteDataSource.getGroupBalances(event.groupId);
      emit(state.copyWith(
        isBalancesLoading: false,
        balances: balances,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupBalancesLoadRequested AppException', error: error);
      emit(state.copyWith(
        isBalancesLoading: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupBalancesLoadRequested unexpected error', error: error);
      emit(state.copyWith(
        isBalancesLoading: false,
        errorMessage: 'Không thể tải bảng đối chiếu công nợ',
      ));
    }
  }

  Future<void> _onDebtSettleRequested(
    GroupDebtSettleRequested event,
    Emitter<GroupsState> emit,
  ) async {
    AppLogger.info('[GroupsBloc] GroupDebtSettleRequested amount=${event.amount}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _groupsRemoteDataSource.settleDebt(
        groupId: event.groupId,
        fromMemberId: event.fromMemberId,
        toMemberId: event.toMemberId,
        amount: event.amount,
      );

      // Re-fetch bills and balances
      final bills = await _groupsRemoteDataSource.getGroupBills(event.groupId);
      final balances = await _groupsRemoteDataSource.getGroupBalances(event.groupId);

      emit(state.copyWith(
        isMutating: false,
        bills: bills,
        balances: balances,
        successMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GroupsBloc] GroupDebtSettleRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GroupsBloc] GroupDebtSettleRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  void _onClearMessageRequested(
    GroupsClearMessageRequested event,
    Emitter<GroupsState> emit,
  ) {
    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}
