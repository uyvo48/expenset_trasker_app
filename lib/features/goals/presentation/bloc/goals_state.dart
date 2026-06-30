part of 'goals_bloc.dart';

enum GoalsStatus { initial, loading, success, failure }

class GoalsState {
  const GoalsState({
    this.status = GoalsStatus.initial,
    this.goals = const [],
    this.selectedGoal,
    this.errorMessage,
    this.successMessage,
    this.isMutating = false,
    this.isDetailLoading = false,
  });

  final GoalsStatus status;
  final List<GoalModel> goals;
  final GoalModel? selectedGoal;
  final String? errorMessage;
  final String? successMessage;
  final bool isMutating;
  final bool isDetailLoading;

  GoalsState copyWith({
    GoalsStatus? status,
    List<GoalModel>? goals,
    GoalModel? selectedGoal,
    String? errorMessage,
    String? successMessage,
    bool? isMutating,
    bool? isDetailLoading,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isMutating: isMutating ?? this.isMutating,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
    );
  }
}
