import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/goals_remote_data_source.dart';
import '../../data/models/goal_model.dart';

part 'goals_event.dart';
part 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc({
    GoalsRemoteDataSource? goalsRemoteDataSource,
  })  : _goalsRemoteDataSource =
            goalsRemoteDataSource ?? GoalsRemoteDataSourceImpl(),
        super(const GoalsState()) {
    on<GoalsLoadRequested>(_onLoadRequested);
    on<GoalCreateRequested>(_onCreateRequested);
    on<GoalSelectRequested>(_onSelectRequested);
    on<GoalUpdateRequested>(_onUpdateRequested);
    on<GoalDeleteRequested>(_onDeleteRequested);
    on<GoalAllocateRequested>(_onAllocateRequested);
    on<GoalWithdrawRequested>(_onWithdrawRequested);
    on<GoalsClearMessageRequested>(_onClearMessageRequested);
  }

  final GoalsRemoteDataSource _goalsRemoteDataSource;

  Future<void> _onLoadRequested(
    GoalsLoadRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalsLoadRequested start');
    emit(state.copyWith(
      status: GoalsStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final goals = await _goalsRemoteDataSource.getGoals();
      emit(state.copyWith(
        status: GoalsStatus.success,
        goals: goals,
      ));
      AppLogger.info('[GoalsBloc] GoalsLoadRequested done goalsCount=${goals.length}');
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalsLoadRequested AppException', error: error);
      emit(state.copyWith(
        status: GoalsStatus.failure,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalsLoadRequested unexpected error', error: error);
      emit(state.copyWith(
        status: GoalsStatus.failure,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onCreateRequested(
    GoalCreateRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalCreateRequested name=${event.name}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _goalsRemoteDataSource.createGoal(
        name: event.name,
        targetAmount: event.targetAmount,
        deadline: event.deadline,
        category: event.category,
        autoAllocate: event.autoAllocate,
        allocatePercent: event.allocatePercent,
      );

      final updatedGoals = List<GoalModel>.from(state.goals)..add(result.goal);

      emit(state.copyWith(
        isMutating: false,
        goals: updatedGoals,
        successMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalCreateRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalCreateRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onSelectRequested(
    GoalSelectRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalSelectRequested goalId=${event.goalId}');
    emit(state.copyWith(
      isDetailLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final details = await _goalsRemoteDataSource.getGoalDetails(event.goalId);
      emit(state.copyWith(
        isDetailLoading: false,
        selectedGoal: details,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalSelectRequested AppException', error: error);
      emit(state.copyWith(
        isDetailLoading: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalSelectRequested unexpected error', error: error);
      emit(state.copyWith(
        isDetailLoading: false,
        errorMessage: 'Không thể tải tiến trình mục tiêu',
      ));
    }
  }

  Future<void> _onUpdateRequested(
    GoalUpdateRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalUpdateRequested goalId=${event.id}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _goalsRemoteDataSource.updateGoal(
        id: event.id,
        name: event.name,
        targetAmount: event.targetAmount,
        deadline: event.deadline,
        category: event.category,
        autoAllocate: event.autoAllocate,
        allocatePercent: event.allocatePercent,
      );

      final updatedGoals = state.goals.map((g) {
        return g.id == event.id ? result.goal : g;
      }).toList();

      emit(state.copyWith(
        isMutating: false,
        goals: updatedGoals,
        selectedGoal: state.selectedGoal?.id == event.id ? result.goal : state.selectedGoal,
        successMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalUpdateRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalUpdateRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onDeleteRequested(
    GoalDeleteRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalDeleteRequested goalId=${event.goalId}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _goalsRemoteDataSource.deleteGoal(event.goalId);

      final updatedGoals = state.goals.where((g) => g.id != event.goalId).toList();

      emit(state.copyWith(
        isMutating: false,
        goals: updatedGoals,
        selectedGoal: state.selectedGoal?.id == event.goalId ? null : state.selectedGoal,
        successMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalDeleteRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalDeleteRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onAllocateRequested(
    GoalAllocateRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalAllocateRequested goalId=${event.goalId} amount=${event.amount}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _goalsRemoteDataSource.allocateMoney(
        id: event.goalId,
        amount: event.amount,
      );

      final updatedGoals = state.goals.map((g) {
        return g.id == event.goalId ? result.goal : g;
      }).toList();

      emit(state.copyWith(
        isMutating: false,
        goals: updatedGoals,
        selectedGoal: result.goal,
        successMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalAllocateRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalAllocateRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onWithdrawRequested(
    GoalWithdrawRequested event,
    Emitter<GoalsState> emit,
  ) async {
    AppLogger.info('[GoalsBloc] GoalWithdrawRequested goalId=${event.goalId} amount=${event.amount}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _goalsRemoteDataSource.withdrawMoney(
        id: event.goalId,
        amount: event.amount,
      );

      final updatedGoals = state.goals.map((g) {
        return g.id == event.goalId ? result.goal : g;
      }).toList();

      emit(state.copyWith(
        isMutating: false,
        goals: updatedGoals,
        selectedGoal: result.goal,
        successMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[GoalsBloc] GoalWithdrawRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[GoalsBloc] GoalWithdrawRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  void _onClearMessageRequested(
    GoalsClearMessageRequested event,
    Emitter<GoalsState> emit,
  ) {
    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}
