part of 'goals_bloc.dart';

abstract class GoalsEvent {
  const GoalsEvent();
}

class GoalsLoadRequested extends GoalsEvent {
  const GoalsLoadRequested();
}

class GoalCreateRequested extends GoalsEvent {
  const GoalCreateRequested({
    required this.name,
    required this.targetAmount,
    this.deadline,
    required this.category,
    this.autoAllocate = false,
    this.allocatePercent,
  });

  final String name;
  final int targetAmount;
  final DateTime? deadline;
  final String category;
  final bool autoAllocate;
  final int? allocatePercent;
}

class GoalSelectRequested extends GoalsEvent {
  const GoalSelectRequested(this.goalId);

  final int goalId;
}

class GoalUpdateRequested extends GoalsEvent {
  const GoalUpdateRequested({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.deadline,
    required this.category,
    this.autoAllocate = false,
    this.allocatePercent,
  });

  final int id;
  final String name;
  final int targetAmount;
  final DateTime? deadline;
  final String category;
  final bool autoAllocate;
  final int? allocatePercent;
}

class GoalDeleteRequested extends GoalsEvent {
  const GoalDeleteRequested(this.goalId);

  final int goalId;
}

class GoalAllocateRequested extends GoalsEvent {
  const GoalAllocateRequested({
    required this.goalId,
    required this.amount,
  });

  final int goalId;
  final int amount;
}

class GoalWithdrawRequested extends GoalsEvent {
  const GoalWithdrawRequested({
    required this.goalId,
    required this.amount,
  });

  final int goalId;
  final int amount;
}

class GoalsClearMessageRequested extends GoalsEvent {
  const GoalsClearMessageRequested();
}
