import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/widgets/shared_widgets.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../data/models/transaction_model.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({
    super.key,
    required this.state,
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
    required this.onEdit,
    required this.onDelete,
  });

  final HomeState state;
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
  final ValueChanged<TransactionModel> onEdit;
  final ValueChanged<TransactionModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Giao dịch',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        FilterPanel(
          keywordController: keywordController,
          categoryController: categoryController,
          typeFilter: typeFilter,
          startDate: startDate,
          endDate: endDate,
          isBusy: state.isMutating,
          onTypeChanged: onTypeChanged,
          onPickStartDate: onPickStartDate,
          onPickEndDate: onPickEndDate,
          onClearStartDate: onClearStartDate,
          onClearEndDate: onClearEndDate,
          onApply: onApplyFilter,
          onClear: onClearFilter,
        ),
        const SizedBox(height: 16),
        if (state.transactions.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch',
            message: 'Tạo giao dịch đầu tiên hoặc đổi bộ lọc tìm kiếm.',
          )
        else
          ...state.transactions.map(
            (transaction) => TransactionTile(
              transaction: transaction,
              onEdit: () => onEdit(transaction),
              onDelete: () => onDelete(transaction),
            ),
          ),
      ],
    );
  }
}

class TransactionFormDialog extends StatefulWidget {
  const TransactionFormDialog({super.key, this.transaction});

  final TransactionModel? transaction;

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
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
                  validator: _validatePositiveInt,
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
                  validator: _validateOptionalPositiveInt,
                ),
                const SizedBox(height: 12),
                DatePickerButton(
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

class DatePickerButton extends StatelessWidget {
  const DatePickerButton({
    super.key,
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

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
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
              child: DatePickerButton(
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
              child: DatePickerButton(
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

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
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

String? _validatePositiveInt(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number <= 0) {
    return 'Vui lòng nhập số nguyên lớn hơn 0';
  }
  return null;
}

String? _validateOptionalPositiveInt(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _validatePositiveInt(value);
}
