enum TransactionKind {
  income,
  expense;

  String get apiValue => name;

  String get label {
    return switch (this) {
      TransactionKind.income => 'Thu nhập',
      TransactionKind.expense => 'Chi tiêu',
    };
  }

  static TransactionKind fromApiValue(String value) {
    return value == 'income' ? TransactionKind.income : TransactionKind.expense;
  }
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.date,
    this.createdAt,
  });

  final int id;
  final int userId;
  final int? walletId;
  final TransactionKind type;
  final int amount;
  final String category;
  final String description;
  final DateTime? date;
  final DateTime? createdAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      walletId: _asNullableInt(json['wallet_id']),
      type: TransactionKind.fromApiValue(json['type'] as String? ?? 'expense'),
      amount: _asInt(json['amount']),
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class TransactionPayload {
  const TransactionPayload({
    required this.amount,
    required this.category,
    required this.type,
    this.description,
    this.date,
    this.walletId,
  });

  final int amount;
  final String category;
  final TransactionKind type;
  final String? description;
  final DateTime? date;
  final int? walletId;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'type': type.apiValue,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (date != null) 'date': date!.toUtc().toIso8601String(),
      if (walletId != null) 'wallet_id': walletId,
    };
  }
}

class TransactionSearchFilter {
  const TransactionSearchFilter({
    this.keyword,
    this.category,
    this.type,
    this.startDate,
    this.endDate,
  });

  final String? keyword;
  final String? category;
  final TransactionKind? type;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, String> toQueryParameters() {
    return {
      if (keyword != null && keyword!.trim().isNotEmpty)
        'q': keyword!.trim(),
      if (category != null && category!.trim().isNotEmpty)
        'category': category!.trim(),
      if (type != null) 'type': type!.apiValue,
      if (startDate != null) 'start_date': startDate!.toUtc().toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toUtc().toIso8601String(),
    };
  }

  bool get isEmpty => toQueryParameters().isEmpty;
}
