import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/widgets/auth_validators.dart';
import '../../../auth/presentation/widgets/shared_widgets.dart';
import '../../data/models/group_balance_model.dart';
import '../../data/models/group_bill_model.dart';
import '../../data/models/group_model.dart';
import '../bloc/groups_bloc.dart';

class GroupDetailsView extends StatefulWidget {
  const GroupDetailsView({super.key, required this.groupId});

  final int groupId;

  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<GroupsBloc>().add(GroupSelectRequested(widget.groupId));
    context.read<GroupsBloc>().add(GroupBillsLoadRequested(widget.groupId));
    context.read<GroupsBloc>().add(GroupBalancesLoadRequested(widget.groupId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddMemberDialog(GroupModel group) {
    final groupsBloc = context.read<GroupsBloc>();
    showDialog<({String? email, String? guestName})>(
      context: context,
      builder: (context) => const _AddMemberDialog(),
    ).then((result) {
      if (result != null) {
        groupsBloc.add(GroupAddMemberRequested(
              groupId: group.id,
              email: result.email,
              guestName: result.guestName,
            ));
      }
    });
  }

  void _showCreateBillDialog(GroupModel group) {
    final groupsBloc = context.read<GroupsBloc>();
    // Use widget.groupId directly so we always use the correct ID
    // even if state.selectedGroup is not yet refreshed
    final groupId = widget.groupId;
    showDialog<({
      int amount,
      int payerMemberId,
      String category,
      String? description,
      String splitMethod,
      List<Map<String, dynamic>> splits
    })>(
      context: context,
      builder: (context) => _BillFormDialog(group: group),
    ).then((result) {
      if (result != null) {
        groupsBloc.add(GroupBillCreateRequested(
              groupId: groupId,
              amount: result.amount,
              payerMemberId: result.payerMemberId,
              category: result.category,
              description: result.description,
              splitMethod: result.splitMethod,
              splits: result.splits,
            ));
      }
    });
  }

  void _showSettleDialog(int fromMemberId, int toMemberId, int amount, List<GroupMemberModel> members) {
    final groupsBloc = context.read<GroupsBloc>();
    showDialog<bool>(
      context: context,
      builder: (context) => _SettleConfirmDialog(
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amount: amount,
        members: members,
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        groupsBloc.add(GroupDebtSettleRequested(
              groupId: widget.groupId,
              fromMemberId: fromMemberId,
              toMemberId: toMemberId,
              amount: amount,
            ));
      }
    });
  }

  void _deleteMember(int memberId, String displayName) {
    final groupsBloc = context.read<GroupsBloc>();
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "$displayName" khỏi nhóm không?'),
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
        groupsBloc.add(GroupDeleteMemberRequested(
              groupId: widget.groupId,
              memberId: memberId,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupsBloc, GroupsState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.successMessage != null) {
          _showMessage(state.successMessage!);
          context.read<GroupsBloc>().add(const GroupsClearMessageRequested());
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
          context.read<GroupsBloc>().add(const GroupsClearMessageRequested());
        }
      },
      child: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          final group = state.selectedGroup;

          if (group == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chi tiết nhóm')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final members = group.members ?? [];
          final isBusy = state.isMutating;

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name),
                  if (group.description != null && group.description!.isNotEmpty)
                    Text(
                      group.description!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                ],
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Thành viên'),
                  Tab(text: 'Hóa đơn'),
                  Tab(text: 'Công nợ'),
                ],
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Members
                  _buildMembersTab(members, isBusy, group),
                  // Tab 2: Bills
                  _buildBillsTab(state.bills, state.isBillsLoading, isBusy, group, members),
                  // Tab 3: Balances / Debt settlement
                  _buildBalancesTab(state.balances, state.isBalancesLoading, members),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersTab(List<GroupMemberModel> members, bool isBusy, GroupModel group) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thành viên nhóm (${members.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : () => _showAddMemberDialog(group),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isAdmin = member.role == 'admin';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(member.displayName.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(member.displayName),
                  subtitle: Text(isAdmin ? 'Trưởng nhóm' : 'Thành viên'),
                  trailing: !isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                          onPressed: isBusy ? null : () => _deleteMember(member.id, member.displayName),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsTab(
    List<GroupBillModel> bills,
    bool isLoading,
    bool isBusy,
    GroupModel group,
    List<GroupMemberModel> members,
  ) {
    if (isLoading && bills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách hóa đơn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              FilledButton.icon(
                onPressed: isBusy || members.isEmpty ? null : () => _showCreateBillDialog(group),
                icon: const Icon(Icons.add),
                label: const Text('Tạo hóa đơn'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bills.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có hóa đơn',
                message: 'Thêm hóa đơn chi tiêu chung để phân chia chi phí.',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final payer = members.firstWhere(
                    (m) => m.id == bill.payerMemberId,
                    orElse: () => GroupMemberModel(
                      id: bill.payerMemberId,
                      groupId: group.id,
                      role: 'member',
                      guestName: 'Thành viên #${bill.payerMemberId}',
                    ),
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        bill.description ?? bill.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Người trả: ${payer.displayName} • ${bill.splitMethod == 'equal' ? 'Chia đều' : 'Tùy chỉnh'}',
                      ),
                      trailing: Text(
                        formatVnd(bill.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalancesTab(
    List<GroupBalanceModel> balances,
    bool isLoading,
    List<GroupMemberModel> members,
  ) {
    if (isLoading && balances.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasDebts = balances.any((b) => b.owes.isNotEmpty);

    if (!hasDebts) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Đã sạch nợ',
          message: 'Tuyệt vời! Hiện tại không có công nợ nào chưa thanh toán trong nhóm.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bảng đối chiếu công nợ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: balances.length,
              itemBuilder: (context, index) {
                final balance = balances[index];
                if (balance.owes.isEmpty) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        ...balance.owes.map((owe) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_forward, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: [
                                        const TextSpan(text: 'Nợ '),
                                        TextSpan(
                                          text: owe.username,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(text: ': '),
                                        TextSpan(
                                          text: formatVnd(owe.amount),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _showSettleDialog(
                                    balance.memberId,
                                    owe.memberId,
                                    owe.amount,
                                    members,
                                  ),
                                  icon: const Icon(Icons.payment, size: 14),
                                  label: const Text('Tất toán', style: TextStyle(fontSize: 11)),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _guestNameController = TextEditingController();

  bool _isGuest = false;

  @override
  void dispose() {
    _emailController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      email: _isGuest ? null : _emailController.text.trim(),
      guestName: _isGuest ? _guestNameController.text.trim() : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm thành viên nhóm'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Người dùng hệ thống'),
                    selected: !_isGuest,
                    onSelected: (val) => setState(() => _isGuest = !val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Thành viên ảo (Guest)'),
                    selected: _isGuest,
                    onSelected: (val) => setState(() => _isGuest = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isGuest)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email thành viên',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
              )
            else
              TextFormField(
                controller: _guestNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thành viên khách',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên khách' : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}

class _BillFormDialog extends StatefulWidget {
  const _BillFormDialog({required this.group});

  final GroupModel group;

  @override
  State<_BillFormDialog> createState() => _BillFormDialogState();
}

class _BillFormDialogState extends State<_BillFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Valid categories accepted by the backend's `oneof` validation
  static const _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Health',
    'Accommodation',
    'Utilities',
    'Education',
    'Other',
  ];

  int? _payerMemberId;
  String _splitMethod = 'equal';
  String _category = 'Food';
  late List<bool> _selectedMembers;
  late List<TextEditingController> _exactAmountControllers;

  @override
  void initState() {
    super.initState();
    final members = widget.group.members ?? [];
    if (members.isNotEmpty) {
      _payerMemberId = members.first.id;
    }
    _selectedMembers = List<bool>.generate(members.length, (_) => true);
    _exactAmountControllers = List<TextEditingController>.generate(
      members.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (final c in _exactAmountControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = int.tryParse(_amountController.text.trim()) ?? 0;
    final members = widget.group.members ?? [];
    final List<Map<String, dynamic>> splits = [];

    if (_splitMethod == 'equal') {
      for (int i = 0; i < members.length; i++) {
        if (_selectedMembers[i]) {
          splits.add({
            'group_member_id': members[i].id,
          });
        }
      }
      if (splits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất 1 thành viên chịu nợ')),
        );
        return;
      }
    } else {
      int sum = 0;
      for (int i = 0; i < members.length; i++) {
        if (_selectedMembers[i]) {
          final val = int.tryParse(_exactAmountControllers[i].text.trim()) ?? 0;
          sum += val;
          splits.add({
            'group_member_id': members[i].id,
            'amount': val,
          });
        }
      }
      if (sum != totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tổng số tiền tùy chỉnh ($sum) phải bằng tổng tiền hóa đơn ($totalAmount)')),
        );
        return;
      }
    }

    Navigator.pop(context, (
      amount: totalAmount,
      payerMemberId: _payerMemberId ?? 0,
      category: _category,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      splitMethod: _splitMethod,
      splits: splits,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members ?? [];

    return AlertDialog(
      title: const Text('Tạo hóa đơn chi tiêu mới'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tổng số tiền',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                    suffixText: 'đ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Nhập số tiền';
                    final val = int.tryParse(value);
                    if (val == null || val <= 0) return 'Số tiền phải lớn hơn 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _payerMemberId,
                  decoration: const InputDecoration(
                    labelText: 'Người thanh toán',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: members.map((m) {
                    return DropdownMenuItem<int>(
                      value: m.id,
                      child: Text(m.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _payerMemberId = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả ghi chú',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Phân chia chi phí',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Chia đều'),
                        selected: _splitMethod == 'equal',
                        onSelected: (val) => setState(() => _splitMethod = 'equal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Tùy chỉnh'),
                        selected: _splitMethod == 'exact',
                        onSelected: (val) => setState(() => _splitMethod = 'exact'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(members.length, (i) {
                  final member = members[i];

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(member.displayName),
                    value: _selectedMembers[i],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMembers[i] = val);
                      }
                    },
                    subtitle: _splitMethod == 'exact' && _selectedMembers[i]
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: TextFormField(
                              controller: _exactAmountControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số tiền chịu nợ (đ)',
                                isDense: true,
                              ),
                              validator: (val) {
                                if (_splitMethod != 'exact') return null;
                                if (!_selectedMembers[i]) return null;
                                if (val == null || val.trim().isEmpty) return 'Nhập tiền';
                                final v = int.tryParse(val);
                                if (v == null || v <= 0) return 'Số tiền phải > 0';
                                return null;
                              },
                            ),
                          )
                        : null,
                  );
                }),
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Tạo hóa đơn'),
        ),
      ],
    );
  }
}

class _SettleConfirmDialog extends StatelessWidget {
  const _SettleConfirmDialog({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.members,
  });

  final int fromMemberId;
  final int toMemberId;
  final int amount;
  final List<GroupMemberModel> members;

  @override
  Widget build(BuildContext context) {
    final fromMember = members.firstWhere((m) => m.id == fromMemberId);
    final toMember = members.firstWhere((m) => m.id == toMemberId);

    return AlertDialog(
      title: const Text('Xác nhận tất toán nợ'),
      content: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
          children: [
            const TextSpan(text: 'Xác nhận ghi nhận việc '),
            TextSpan(
              text: fromMember.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' đã thanh toán khoản nợ '),
            TextSpan(
              text: formatVnd(amount),
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' cho '),
            TextSpan(
              text: toMember.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
