class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyBalance,
  });

  final int totalIncome;
  final int totalExpense;
  final int balance;
  final int transactionCount;
  final int monthlyIncome;
  final int monthlyExpense;
  final int monthlyBalance;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalIncome: _asInt(json['total_income']),
      totalExpense: _asInt(json['total_expense']),
      balance: _asInt(json['balance']),
      transactionCount: _asInt(json['transaction_count']),
      monthlyIncome: _asInt(json['monthly_income']),
      monthlyExpense: _asInt(json['monthly_expense']),
      monthlyBalance: _asInt(json['monthly_balance']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
