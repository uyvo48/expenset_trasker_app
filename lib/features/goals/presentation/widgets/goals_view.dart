import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/widgets/shared_widgets.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../data/models/goal_model.dart';
import '../bloc/goals_bloc.dart';

class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddEditGoalDialog(BuildContext context, {GoalModel? goal}) {
    final goalsBloc = context.read<GoalsBloc>();
    showDialog<({
      String name,
      int targetAmount,
      DateTime? deadline,
      String category,
      bool autoAllocate,
      int? allocatePercent
    })>(
      context: context,
      builder: (context) => _GoalFormDialog(goal: goal),
    ).then((result) {
      if (result != null) {
        if (goal == null) {
          goalsBloc.add(GoalCreateRequested(
                name: result.name,
                targetAmount: result.targetAmount,
                deadline: result.deadline,
                category: result.category,
                autoAllocate: result.autoAllocate,
                allocatePercent: result.allocatePercent,
              ));
        } else {
          goalsBloc.add(GoalUpdateRequested(
                id: goal.id,
                name: result.name,
                targetAmount: result.targetAmount,
                deadline: result.deadline,
                category: result.category,
                autoAllocate: result.autoAllocate,
                allocatePercent: result.allocatePercent,
              ));
        }
      }
    });
  }

  void _showGoalDetails(BuildContext context, GoalModel goal) {
    context.read<GoalsBloc>().add(GoalSelectRequested(goal.id));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<GoalsBloc>()),
            BlocProvider.value(value: context.read<HomeBloc>()),
          ],
          child: BlocListener<GoalsBloc, GoalsState>(
            listenWhen: (prev, curr) =>
                prev.successMessage != curr.successMessage ||
                prev.errorMessage != curr.errorMessage,
            listener: (listenerContext, state) {
              if (state.successMessage != null) {
                _showMessage(listenerContext, state.successMessage!);
                listenerContext.read<GoalsBloc>().add(const GoalsClearMessageRequested());
                // Reload dashboard/transactions since allocate/withdraw modifies balance and creates transactions
                listenerContext.read<HomeBloc>().add(const HomeLoadRequested());
              }
              if (state.errorMessage != null) {
                showDialog<void>(
                  context: listenerContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Thông báo'),
                    content: Text(state.errorMessage!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
                listenerContext.read<GoalsBloc>().add(const GoalsClearMessageRequested());
              }
            },
            child: _GoalDetailsSheet(
              initialGoal: goal,
              onEdit: (g) {
                Navigator.pop(modalContext);
                _showAddEditGoalDialog(context, goal: g);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoalsBloc, GoalsState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.successMessage != null) {
          _showMessage(context, state.successMessage!);
          context.read<GoalsBloc>().add(const GoalsClearMessageRequested());
        }
        if (state.errorMessage != null) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Thông báo'),
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
          context.read<GoalsBloc>().add(const GoalsClearMessageRequested());
        }
      },
      child: BlocBuilder<GoalsBloc, GoalsState>(
        builder: (context, state) {
          final isBusy = state.status == GoalsStatus.loading || state.isMutating;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mục tiêu tích lũy',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isBusy ? null : () => _showAddEditGoalDialog(context),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Thêm mục tiêu'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.status == GoalsStatus.loading && state.goals.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.goals.isEmpty)
                const EmptyState(
                  icon: Icons.track_changes,
                  title: 'Chưa có mục tiêu',
                  message: 'Đặt mục tiêu tích lũy để tiết kiệm mua sắm, đầu tư hoặc quỹ khẩn cấp.',
                )
              else
                ...state.goals.map((goal) {
                  final progress = goal.progress.clamp(0.0, 100.0);
                  final progressPercent = progress / 100.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showGoalDetails(context, goal),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    goal.categoryLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tiến độ: ${progress.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${formatVnd(goal.currentAmount)} / ${formatVnd(goal.targetAmount)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (goal.deadline != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Hạn: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                Text(
                                  goal.daysLeft > 0
                                      ? 'Còn ${goal.daysLeft} ngày'
                                      : (goal.isExpired ? 'Đã quá hạn' : 'Hôm nay'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: goal.isExpired ? Colors.red : Colors.grey,
                                    fontWeight: goal.isExpired ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _GoalFormDialog extends StatefulWidget {
  const _GoalFormDialog({this.goal});

  final GoalModel? goal;

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _percentController = TextEditingController();

  String _category = 'savings';
  DateTime? _deadline;
  bool _autoAllocate = false;

  final List<({String value, String label})> _categories = const [
    (value: 'savings', label: 'Tiết kiệm'),
    (value: 'travel', label: 'Du lịch'),
    (value: 'emergency', label: 'Khẩn cấp'),
    (value: 'education', label: 'Giáo dục'),
    (value: 'investment', label: 'Đầu tư'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = widget.goal!.targetAmount.toString();
      _category = widget.goal!.category;
      _deadline = widget.goal!.deadline;
      _autoAllocate = widget.goal!.autoAllocate;
      _percentController.text = widget.goal!.allocatePercent?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  void _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final target = int.tryParse(_targetController.text) ?? 0;
    final percent = _autoAllocate ? (int.tryParse(_percentController.text) ?? 0) : null;

    Navigator.pop(context, (
      name: _nameController.text.trim(),
      targetAmount: target,
      deadline: _deadline,
      category: _category,
      autoAllocate: _autoAllocate,
      allocatePercent: percent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goal != null;

    return AlertDialog(
      title: Text(isEdit ? 'Cập nhật mục tiêu' : 'Tạo mục tiêu mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên mục tiêu',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên mục tiêu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền cần tích lũy',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  suffixText: 'đ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final val = int.tryParse(value);
                  if (val == null || val <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(_deadline == null
                    ? 'Chọn hạn tích lũy'
                    : 'Hạn: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                trailing: TextButton(
                  onPressed: _pickDeadline,
                  child: const Text('Chọn'),
                ),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trích tiền tự động'),
                subtitle: const Text('Tự động trích phần trăm từ thu nhập mới nhận.'),
                value: _autoAllocate,
                onChanged: (val) => setState(() => _autoAllocate = val),
              ),
              if (_autoAllocate) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _percentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Phần trăm trích (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: (value) {
                    if (!_autoAllocate) return null;
                    if (value == null || value.trim().isEmpty) return 'Nhập từ 1 đến 100';
                    final val = int.tryParse(value);
                    if (val == null || val < 1 || val > 100) return 'Phần trăm từ 1 - 100%';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Cập nhật' : 'Tạo mục tiêu'),
        ),
      ],
    );
  }
}

class _GoalDetailsSheet extends StatelessWidget {
  const _GoalDetailsSheet({
    required this.initialGoal,
    required this.onEdit,
  });

  final GoalModel initialGoal;
  final ValueChanged<GoalModel> onEdit;

  void _showTransactionDialog(BuildContext context, bool isDeposit, GoalModel goal) {
    final goalsBloc = context.read<GoalsBloc>();
    showDialog<int>(
      context: context,
      builder: (context) => _GoalTransactionAmountDialog(isDeposit: isDeposit),
    ).then((amount) {
      if (amount != null && amount > 0) {
        if (isDeposit) {
          goalsBloc.add(GoalAllocateRequested(
                goalId: goal.id,
                amount: amount,
              ));
        } else {
          goalsBloc.add(GoalWithdrawRequested(
                goalId: goal.id,
                amount: amount,
              ));
        }
      }
    });
  }

  void _deleteGoal(BuildContext context, GoalModel goal) {
    final goalsBloc = context.read<GoalsBloc>();
    final rootContext = context;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        goalsBloc.add(GoalDeleteRequested(goal.id));
        if (rootContext.mounted) {
          Navigator.pop(rootContext); // Close details sheet
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 24,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: BlocBuilder<GoalsBloc, GoalsState>(
        builder: (context, state) {
          final goal = state.selectedGoal ?? initialGoal;
          final isBusy = state.isMutating;
          final progress = goal.progress.clamp(0.0, 100.0);
          final progressPercent = progress / 100.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chỉnh sửa',
                    onPressed: isBusy ? null : () => onEdit(goal),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa mục tiêu',
                    onPressed: isBusy ? null : () => _deleteGoal(context, goal),
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      goal.categoryLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (goal.autoAllocate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tự trích ${goal.allocatePercent}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Đã tích lũy:'),
                  Text(
                    formatVnd(goal.currentAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mục tiêu cần tích lũy:'),
                  Text(
                    formatVnd(goal.targetAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tiến độ: ${progress.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Còn lại cần tích lũy:'),
                  Text(
                    formatVnd(goal.remaining),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (goal.deadline != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hạn tích lũy:'),
                    Text(
                      '${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thời gian còn lại:'),
                  Text(
                    goal.daysLeft > 0
                        ? '${goal.daysLeft} ngày'
                        : (goal.isExpired ? 'Đã quá hạn' : 'Hôm nay'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: goal.isExpired ? Colors.red : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _showTransactionDialog(context, false, goal),
                      icon: const Icon(Icons.remove),
                      label: const Text('Rút tiền'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : () => _showTransactionDialog(context, true, goal),
                      icon: const Icon(Icons.add),
                      label: const Text('Nạp tiền'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalTransactionAmountDialog extends StatefulWidget {
  const _GoalTransactionAmountDialog({required this.isDeposit});

  final bool isDeposit;

  @override
  State<_GoalTransactionAmountDialog> createState() => _GoalTransactionAmountDialogState();
}

class _GoalTransactionAmountDialogState extends State<_GoalTransactionAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, int.tryParse(_amountController.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isDeposit ? 'Nạp tiền tích lũy' : 'Rút tiền về ví'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Số tiền',
            prefixIcon: Icon(Icons.monetization_on_outlined),
            suffixText: 'đ',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
            final val = int.tryParse(value);
            if (val == null || val <= 0) return 'Số tiền phải lớn hơn 0';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
