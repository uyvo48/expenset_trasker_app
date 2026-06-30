import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/widgets/auth_validators.dart';
import '../../../auth/presentation/widgets/shared_widgets.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../data/models/wallet_model.dart';
import '../bloc/wallets_bloc.dart';

class WalletsView extends StatelessWidget {
  const WalletsView({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final walletsBloc = context.read<WalletsBloc>();
    showDialog<({String name, String? description})>(
      context: context,
      builder: (context) => const _WalletFormDialog(),
    ).then((result) {
      if (result != null) {
        walletsBloc.add(WalletCreateRequested(
              name: result.name,
              description: result.description,
            ));
      }
    });
  }

  void _showWalletDetails(BuildContext context, WalletModel wallet, int currentUserId) {
    context.read<WalletsBloc>().add(WalletSelectRequested(wallet.id));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<WalletsBloc>()),
          ],
          child: BlocListener<WalletsBloc, WalletsState>(
            listenWhen: (prev, curr) =>
                prev.successMessage != curr.successMessage ||
                prev.errorMessage != curr.errorMessage,
            listener: (listenerContext, state) {
              if (state.successMessage != null) {
                _showMessage(listenerContext, state.successMessage!);
                listenerContext.read<WalletsBloc>().add(const WalletsClearMessageRequested());
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
                listenerContext.read<WalletsBloc>().add(const WalletsClearMessageRequested());
              }
            },
            child: _WalletDetailsSheet(
              wallet: wallet,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletsBloc, WalletsState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.successMessage != null) {
          _showMessage(context, state.successMessage!);
          context.read<WalletsBloc>().add(const WalletsClearMessageRequested());
        }
        if (state.errorMessage != null) {
          _showMessage(context, state.errorMessage!);
          context.read<WalletsBloc>().add(const WalletsClearMessageRequested());
        }
      },
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          final profile = homeState.profile;
          final currentUserId = profile?.id ?? 0;

          return BlocBuilder<WalletsBloc, WalletsState>(
            builder: (context, state) {
              final isBusy = state.status == WalletsStatus.loading || state.isMutating;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ví của tôi',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: isBusy ? null : () => _showAddWalletDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm ví'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.status == WalletsStatus.loading && state.wallets.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.wallets.isEmpty)
                    const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Chưa có ví tiền',
                      message: 'Tạo ví mới để chia sẻ chi tiêu hoặc quản lý tiền tiết kiệm.',
                    )
                  else
                    ...state.wallets.map(
                      (wallet) {
                        final isOwner = wallet.createdBy == currentUserId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showWalletDetails(context, wallet, currentUserId),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                    child: const Icon(Icons.account_balance_wallet),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          wallet.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (wallet.description != null && wallet.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            wallet.description!,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOwner
                                                ? Colors.blue.shade50
                                                : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isOwner ? 'Chủ ví' : 'Thành viên',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isOwner
                                                  ? Colors.blue.shade800
                                                  : Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatVnd(wallet.balance),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _WalletFormDialog extends StatefulWidget {
  const _WalletFormDialog();

  @override
  State<_WalletFormDialog> createState() => _WalletFormDialogState();
}

class _WalletFormDialogState extends State<_WalletFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm ví mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên ví',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên ví';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.description_outlined),
              ),
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
          child: const Text('Tạo ví'),
        ),
      ],
    );
  }
}

class _WalletDetailsSheet extends StatelessWidget {
  const _WalletDetailsSheet({
    required this.wallet,
    required this.currentUserId,
  });

  final WalletModel wallet;
  final int currentUserId;

  void _showInviteDialog(BuildContext context) {
    final walletsBloc = context.read<WalletsBloc>();
    showDialog<String>(
      context: context,
      builder: (context) => const _InviteMemberDialog(),
    ).then((email) {
      if (email != null && email.isNotEmpty) {
        walletsBloc.add(WalletInviteMemberRequested(
              walletId: wallet.id,
              email: email,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = wallet.createdBy == currentUserId;

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
      child: BlocBuilder<WalletsBloc, WalletsState>(
        builder: (context, state) {
          final detail = state.selectedWallet ?? wallet;
          final members = detail.members ?? [];
          final isBusy = state.isMutating;

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
              Text(
                detail.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (detail.description != null && detail.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  detail.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số dư:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    formatVnd(detail.balance),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thành viên (${members.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isOwner)
                    TextButton.icon(
                      onPressed: isBusy ? null : () => _showInviteDialog(context),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Mời'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.isDetailLoading && members.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Chưa có thành viên nào tham gia.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isMemberOwner = member.id == detail.createdBy;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(member.username.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(member.username),
                        subtitle: Text(member.email),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMemberOwner ? Colors.blue.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isMemberOwner ? 'Chủ ví' : 'Thành viên',
                            style: TextStyle(
                              fontSize: 9,
                              color: isMemberOwner ? Colors.blue.shade800 : Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
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

class _InviteMemberDialog extends StatefulWidget {
  const _InviteMemberDialog();

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mời thành viên mới'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email của người nhận',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: validateEmail,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Gửi lời mời'),
        ),
      ],
    );
  }
}
