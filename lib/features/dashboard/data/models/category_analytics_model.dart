class CategoryAnalyticsModel {
  const CategoryAnalyticsModel({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });

  final String category;
  final int totalAmount;
  final double percentage;

  factory CategoryAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return CategoryAnalyticsModel(
      category: json['category'] as String? ?? '',
      totalAmount: _asInt(json['total_amount']),
      percentage: _asDouble(json['percentage']),
    );
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
    return 0;
  }
}
