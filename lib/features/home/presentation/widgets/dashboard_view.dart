import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/shared_widgets.dart';
import '../bloc/home_bloc.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.state});

  final HomeState state;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.state.dashboard;
    final errorMessage = widget.state.errorMessage;

    if (dashboard == null) {
      return EmptyState(
        icon: Icons.space_dashboard_outlined,
        title: 'Chưa có dữ liệu tổng quan',
        message: errorMessage ?? 'Nhấn tải lại để lấy dữ liệu mới nhất.',
      );
    }

    final filteredAnalytics = widget.state.categoryAnalytics.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ErrorBanner(message: errorMessage),
        Text('Tổng quan', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withAlpha(200),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư hiện tại',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withAlpha(204),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatVnd(dashboard.balance),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: 16,
                                color: Colors.greenAccent[100],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tổng thu (tháng này)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withAlpha(204),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatVnd(dashboard.monthlyIncome),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 16,
                                color: Colors.redAccent[100],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tổng chi (tháng này)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withAlpha(204),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatVnd(dashboard.monthlyExpense),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chi tiêu theo danh mục',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (widget.state.categoryAnalytics.isNotEmpty) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm danh mục...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (filteredAnalytics.isEmpty)
          EmptyState(
            icon: Icons.donut_large_outlined,
            title: _searchQuery.isNotEmpty ? 'Không tìm thấy danh mục' : 'Chưa có thống kê danh mục',
            message: _searchQuery.isNotEmpty ? 'Thử tìm kiếm với từ khóa khác.' : 'Các khoản chi sẽ xuất hiện tại đây.',
          )
        else
          ...filteredAnalytics.map((item) => CategoryAnalyticsTile(item: item)),
      ],
    );
  }
}

class CategoryAnalyticsTile extends StatelessWidget {
  const CategoryAnalyticsTile({super.key, required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final percentage = (item.percentage as double).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.category as String)),
              Text('${percentage.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: percentage / 100),
          const SizedBox(height: 4),
          Text(
            formatVnd(item.totalAmount as int),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
