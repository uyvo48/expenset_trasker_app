import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_validators.dart';
import '../widgets/password_field.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _keywordController = TextEditingController();
  final _categoryFilterController = TextEditingController();

  late final HomeController _homeController;
  int _selectedIndex = 0;
  TransactionKind? _typeFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    widget.controller.addListener(_onControllerChanged);
    _homeController.addListener(_onHomeControllerChanged);
    _homeController.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _homeController.removeListener(_onHomeControllerChanged);
    _homeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _keywordController.dispose();
    _categoryFilterController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onHomeControllerChanged() {
    final profile = _homeController.profile;
    if (profile != null && _usernameController.text.isEmpty) {
      _usernameController.text = profile.username;
      _emailController.text = profile.email;
    }

    if (mounted) setState(() {});
  }

  Future<void> _handleAction(Future<String> Function() action) async {
    try {
      final message = await action();
      _showMessage(message);
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Không thể kết nối máy chủ');
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    await _handleAction(() async {
      final message = await widget.controller.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      return message;
    });
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    await _handleAction(() {
      return _homeController.updateProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );
    });
  }

  Future<void> _applyTransactionFilter() async {
    await _homeController.searchTransactions(
      TransactionSearchFilter(
        keyword: _keywordController.text,
        category: _categoryFilterController.text,
        type: _typeFilter,
        startDate: _startDateFilter,
        endDate: _endDateFilter,
      ),
    );
  }

  Future<void> _clearTransactionFilter() async {
    _keywordController.clear();
    _categoryFilterController.clear();
    setState(() {
      _typeFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
    });
    await _homeController.searchTransactions(const TransactionSearchFilter());
  }

  Future<void> _pickTransactionFilterDate({required bool isStartDate}) async {
    final initialDate = isStartDate
        ? _startDateFilter ?? DateTime.now()
        : _endDateFilter ?? _startDateFilter ?? DateTime.now();
    final firstDate =
        isStartDate ? DateTime(2020) : _startDateFilter ?? DateTime(2020);
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      initialDate: initialDate,
    );

    if (pickedDate == null) return;

    setState(() {
      final normalizedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      if (isStartDate) {
        _startDateFilter = normalizedDate;
        if (_endDateFilter != null &&
            _endDateFilter!.isBefore(normalizedDate)) {
          _endDateFilter = null;
        }
      } else {
        _endDateFilter = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          23,
          59,
          59,
        );
      }
    });
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch'),
        content: Text('Xóa giao dịch "${transaction.category}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _handleAction(
        () => _homeController.deleteTransaction(transaction.id));
  }

  Future<void> _showTransactionForm([TransactionModel? transaction]) async {
    final payload = await showDialog<TransactionPayload>(
      context: context,
      builder: (context) => _TransactionFormDialog(transaction: transaction),
    );

    if (payload == null) return;

    await _handleAction(() {
      if (transaction == null) {
        return _homeController.createTransaction(payload);
      }

      return _homeController.updateTransaction(
        id: transaction.id,
        payload: payload,
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _homeController.isLoading || _homeController.isMutating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: isBusy ? null : _homeController.load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.controller.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: _homeController.isLoading && _homeController.dashboard == null
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _selectedIndex,
                children: [
                  _PageShell(
                    child: _DashboardView(controller: _homeController),
                  ),
                  _PageShell(
                    child: _TransactionsView(
                      controller: _homeController,
                      keywordController: _keywordController,
                      categoryController: _categoryFilterController,
                      typeFilter: _typeFilter,
                      startDate: _startDateFilter,
                      endDate: _endDateFilter,
                      onTypeChanged: (value) {
                        setState(() => _typeFilter = value);
                      },
                      onPickStartDate: () {
                        _pickTransactionFilterDate(isStartDate: true);
                      },
                      onPickEndDate: () {
                        _pickTransactionFilterDate(isStartDate: false);
                      },
                      onClearStartDate: () {
                        setState(() => _startDateFilter = null);
                      },
                      onClearEndDate: () {
                        setState(() => _endDateFilter = null);
                      },
                      onApplyFilter: _applyTransactionFilter,
                      onClearFilter: _clearTransactionFilter,
                      onAdd: () => _showTransactionForm(),
                      onEdit: _showTransactionForm,
                      onDelete: _deleteTransaction,
                    ),
                  ),
                  _PageShell(
                    child: _ProfileView(
                      authController: widget.controller,
                      homeController: _homeController,
                      profileFormKey: _profileFormKey,
                      passwordFormKey: _passwordFormKey,
                      usernameController: _usernameController,
                      emailController: _emailController,
                      oldPasswordController: _oldPasswordController,
                      newPasswordController: _newPasswordController,
                      onUpdateProfile: _updateProfile,
                      onChangePassword: _changePassword,
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final dashboard = controller.dashboard;
    final errorMessage = controller.errorMessage;

    if (dashboard == null) {
      return _EmptyState(
        icon: Icons.space_dashboard_outlined,
        title: 'Chưa có dữ liệu tổng quan',
        message: errorMessage ?? 'Nhấn tải lại để lấy dữ liệu mới nhất.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) _ErrorBanner(message: errorMessage),
        Text('Tổng quan', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              icon: Icons.trending_up,
              label: 'Tổng thu',
              value: formatVnd(dashboard.totalIncome),
            ),
            _MetricTile(
              icon: Icons.trending_down,
              label: 'Tổng chi',
              value: formatVnd(dashboard.totalExpense),
            ),
            _MetricTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Số dư',
              value: formatVnd(dashboard.balance),
            ),
            _MetricTile(
              icon: Icons.sync_alt,
              label: 'Giao dịch',
              value: dashboard.transactionCount.toString(),
            ),
            _MetricTile(
              icon: Icons.calendar_month_outlined,
              label: 'Thu tháng này',
              value: formatVnd(dashboard.monthlyIncome),
            ),
            _MetricTile(
              icon: Icons.event_busy_outlined,
              label: 'Chi tháng này',
              value: formatVnd(dashboard.monthlyExpense),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Chi tiêu theo danh mục',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (controller.categoryAnalytics.isEmpty)
          const _EmptyState(
            icon: Icons.donut_large_outlined,
            title: 'Chưa có thống kê danh mục',
            message: 'Các khoản chi sẽ xuất hiện tại đây.',
          )
        else
          ...controller.categoryAnalytics.map(_CategoryAnalyticsTile.new),
      ],
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView({
    required this.controller,
    required this.keywordController,
    required this.categoryController,
    required this.typeFilter,
    required this.startDate,
    required this.endDate,
    required this.onTypeChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearStartDate,
    required this.onClearEndDate,
    required this.onApplyFilter,
    required this.onClearFilter,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeController controller;
  final TextEditingController keywordController;
  final TextEditingController categoryController;
  final TransactionKind? typeFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<TransactionKind?> onTypeChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearStartDate;
  final VoidCallback onClearEndDate;
  final VoidCallback onApplyFilter;
  final VoidCallback onClearFilter;
  final VoidCallback onAdd;
  final ValueChanged<TransactionModel> onEdit;
  final ValueChanged<TransactionModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Giao dịch',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            FilledButton.icon(
              onPressed: controller.isMutating ? null : onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FilterPanel(
          keywordController: keywordController,
          categoryController: categoryController,
          typeFilter: typeFilter,
          startDate: startDate,
          endDate: endDate,
          isBusy: controller.isMutating,
          onTypeChanged: onTypeChanged,
          onPickStartDate: onPickStartDate,
          onPickEndDate: onPickEndDate,
          onClearStartDate: onClearStartDate,
          onClearEndDate: onClearEndDate,
          onApply: onApplyFilter,
          onClear: onClearFilter,
        ),
        const SizedBox(height: 16),
        if (controller.transactions.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch',
            message: 'Tạo giao dịch đầu tiên hoặc đổi bộ lọc tìm kiếm.',
          )
        else
          ...controller.transactions.map(
            (transaction) => _TransactionTile(
              transaction: transaction,
              onEdit: () => onEdit(transaction),
              onDelete: () => onDelete(transaction),
            ),
          ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.authController,
    required this.homeController,
    required this.profileFormKey,
    required this.passwordFormKey,
    required this.usernameController,
    required this.emailController,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.onUpdateProfile,
    required this.onChangePassword,
  });

  final AuthController authController;
  final HomeController homeController;
  final GlobalKey<FormState> profileFormKey;
  final GlobalKey<FormState> passwordFormKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final VoidCallback onUpdateProfile;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    final profile = homeController.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hồ sơ', style: Theme.of(context).textTheme.headlineSmall),
        if (profile?.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Tạo lúc ${formatDateTime(profile!.createdAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Form(
          key: profileFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên hiển thị';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: homeController.isMutating ? null : onUpdateProfile,
                  icon: homeController.isMutating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Cập nhật hồ sơ'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Bảo mật', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: passwordFormKey,
          child: Column(
            children: [
              PasswordField(
                controller: oldPasswordController,
                labelText: 'Mật khẩu cũ',
                prefixIcon: Icons.lock_clock_outlined,
                textInputAction: TextInputAction.next,
                validator: validatePassword,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: newPasswordController,
                labelText: 'Mật khẩu mới',
                prefixIcon: Icons.lock_reset_outlined,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onChangePassword(),
                validator: validatePassword,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: authController.isChangingPassword
                      ? null
                      : onChangePassword,
                  icon: authController.isChangingPassword
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: const Text('Đổi mật khẩu'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionFormDialog extends StatefulWidget {
  const _TransactionFormDialog({this.transaction});

  final TransactionModel? transaction;

  @override
  State<_TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<_TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _walletController;
  late TransactionKind _type;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _amountController = TextEditingController(
      text: transaction?.amount.toString() ?? '',
    );
    _categoryController = TextEditingController(text: transaction?.category);
    _descriptionController = TextEditingController(
      text: transaction?.description,
    );
    _walletController = TextEditingController(
      text: transaction?.walletId?.toString() ?? '',
    );
    _type = transaction?.type ?? TransactionKind.expense;
    _date = transaction?.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date ?? DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = TransactionPayload(
      amount: int.parse(_amountController.text.trim()),
      category: _categoryController.text.trim(),
      type: _type,
      description: _descriptionController.text,
      date: _date,
      walletId: _walletController.text.trim().isEmpty
          ? null
          : int.parse(_walletController.text.trim()),
    );
    AppLogger.debug('[TransactionForm] submit payload=${payload.toJson()}');

    Navigator.pop(
      context,
      payload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return AlertDialog(
      title: Text(isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionKind>(
                  // ignore: deprecated_member_use
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Loại',
                    prefixIcon: Icon(Icons.swap_vert),
                  ),
                  items: TransactionKind.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: validatePositiveInt,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập danh mục';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _walletController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID ví',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: validateOptionalPositiveInt,
                ),
                const SizedBox(height: 12),
                _DatePickerButton(
                  icon: Icons.calendar_month_outlined,
                  label: _date == null ? 'Ngày giao dịch' : formatDate(_date!),
                  onPressed: _pickDate,
                  onClear: _date == null
                      ? null
                      : () {
                          setState(() => _date = null);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
          label: Text(isEditing ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.keywordController,
    required this.categoryController,
    required this.typeFilter,
    required this.startDate,
    required this.endDate,
    required this.isBusy,
    required this.onTypeChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearStartDate,
    required this.onClearEndDate,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController keywordController;
  final TextEditingController categoryController;
  final TransactionKind? typeFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isBusy;
  final ValueChanged<TransactionKind?> onTypeChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearStartDate;
  final VoidCallback onClearEndDate;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: keywordController,
          decoration: const InputDecoration(
            labelText: 'Từ khóa ghi chú',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => onApply(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DatePickerButton(
                icon: Icons.event_outlined,
                label: startDate == null
                    ? 'Từ ngày'
                    : 'Từ ${formatDate(startDate!)}',
                onPressed: isBusy ? null : onPickStartDate,
                onClear: startDate == null || isBusy ? null : onClearStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerButton(
                icon: Icons.event_available_outlined,
                label: endDate == null
                    ? 'Đến ngày'
                    : 'Đến ${formatDate(endDate!)}',
                onPressed: isBusy ? null : onPickEndDate,
                onClear: endDate == null || isBusy ? null : onClearEndDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                onSubmitted: (_) => onApply(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<TransactionKind?>(
                // ignore: deprecated_member_use
                value: typeFilter,
                decoration: const InputDecoration(
                  labelText: 'Loại',
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(
                    value: TransactionKind.income,
                    child: Text('Thu nhập'),
                  ),
                  DropdownMenuItem(
                    value: TransactionKind.expense,
                    child: Text('Chi tiêu'),
                  ),
                ],
                onChanged: onTypeChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Xóa lọc'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isBusy ? null : onApply,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Lọc'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 292,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryAnalyticsTile extends StatelessWidget {
  const _CategoryAnalyticsTile(this.item);

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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionKind.income;
    final color = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward),
        ),
        title: Text(transaction.category),
        subtitle: Text(
          [
            if (transaction.description.isNotEmpty) transaction.description,
            if (transaction.date != null) formatDate(transaction.date!),
            if (transaction.walletId != null) 'Ví #${transaction.walletId}',
          ].join(' • '),
        ),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: 'Sửa',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Xóa',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String? validatePositiveInt(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number <= 0) {
    return 'Vui lòng nhập số nguyên lớn hơn 0';
  }
  return null;
}

String? validateOptionalPositiveInt(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return validatePositiveInt(value);
}

String formatVnd(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '$sign$bufferđ';
}

String formatDate(DateTime value) {
  return '${_two(value.day)}/${_two(value.month)}/${value.year}';
}

String formatDateTime(DateTime value) {
  return '${formatDate(value)} ${_two(value.hour)}:${_two(value.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
