class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.category,
    required this.autoAllocate,
    this.allocatePercent,
    required this.progress,
    required this.remaining,
    required this.daysLeft,
    required this.isOverBudget,
    required this.isExpired,
  });

  final int id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;
  final String category;
  final bool autoAllocate;
  final int? allocatePercent;
  final double progress;
  final int remaining;
  final int daysLeft;
  final bool isOverBudget;
  final bool isExpired;

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    DateTime? deadlineDate;
    if (json['deadline'] != null) {
      deadlineDate = DateTime.tryParse(json['deadline'] as String)?.toLocal();
    }

    return GoalModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      targetAmount: _asInt(json['target_amount']),
      currentAmount: _asInt(json['current_amount']),
      deadline: deadlineDate,
      category: json['category'] as String? ?? 'savings',
      autoAllocate: json['auto_allocate'] as bool? ?? false,
      allocatePercent: json['allocate_percent'] as int?,
      progress: _asDouble(json['progress']),
      remaining: _asInt(json['remaining']),
      daysLeft: json['days_left'] as int? ?? 0,
      isOverBudget: json['is_over_budget'] as bool? ?? false,
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (deadline != null) 'deadline': deadline!.toUtc().toIso8601String(),
      'category': category,
      'auto_allocate': autoAllocate,
      if (allocatePercent != null) 'allocate_percent': allocatePercent,
      'progress': progress,
      'remaining': remaining,
      'days_left': daysLeft,
      'is_over_budget': isOverBudget,
      'is_expired': isExpired,
    };
  }

  GoalModel copyWith({
    int? id,
    String? name,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
    String? category,
    bool? autoAllocate,
    int? allocatePercent,
    double? progress,
    int? remaining,
    int? daysLeft,
    bool? isOverBudget,
    bool? isExpired,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      autoAllocate: autoAllocate ?? this.autoAllocate,
      allocatePercent: allocatePercent ?? this.allocatePercent,
      progress: progress ?? this.progress,
      remaining: remaining ?? this.remaining,
      daysLeft: daysLeft ?? this.daysLeft,
      isOverBudget: isOverBudget ?? this.isOverBudget,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'savings':
        return 'Tiết kiệm';
      case 'travel':
        return 'Du lịch';
      case 'emergency':
        return 'Khẩn cấp';
      case 'education':
        return 'Giáo dục';
      case 'investment':
        return 'Đầu tư';
      default:
        return 'Khác';
    }
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0.0;
  }
}
