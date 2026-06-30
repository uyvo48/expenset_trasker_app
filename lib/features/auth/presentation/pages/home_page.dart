import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../goals/presentation/bloc/goals_bloc.dart';
import '../../../goals/presentation/widgets/goals_view.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/widgets/dashboard_view.dart';
import '../../../profile/presentation/widgets/profile_view.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/widgets/transactions_view.dart';
import '../../../wallets/presentation/bloc/wallets_bloc.dart';
import '../../../wallets/presentation/widgets/wallets_view.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/shared_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  int _selectedIndex = 0;
  TransactionKind? _typeFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _keywordController.dispose();
    _categoryFilterController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _changePassword() {
    if (!_passwordFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthChangePasswordRequested(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        ));
  }

  void _updateProfile() {
    if (!_profileFormKey.currentState!.validate()) return;
    context.read<HomeBloc>().add(HomeUpdateProfileRequested(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
        ));
  }

  void _applyTransactionFilter() {
    context.read<HomeBloc>().add(HomeSearchTransactionsRequested(
          TransactionSearchFilter(
            keyword: _keywordController.text,
            category: _categoryFilterController.text,
            type: _typeFilter,
            startDate: _startDateFilter,
            endDate: _endDateFilter,
          ),
        ));
  }

  void _clearTransactionFilter() {
    _keywordController.clear();
    _categoryFilterController.clear();
    setState(() {
      _typeFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
    });
    context.read<HomeBloc>().add(const HomeSearchTransactionsRequested(TransactionSearchFilter()));
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
    final homeBloc = context.read<HomeBloc>();
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

    homeBloc.add(HomeDeleteTransactionRequested(transaction.id));
  }

  Future<void> _showTransactionForm([TransactionModel? transaction]) async {
    final homeBloc = context.read<HomeBloc>();
    final payload = await showDialog<TransactionPayload>(
      context: context,
      builder: (context) => TransactionFormDialog(transaction: transaction),
    );

    if (payload == null) return;

    if (transaction == null) {
      homeBloc.add(HomeCreateTransactionRequested(payload));
    } else {
      homeBloc.add(HomeUpdateTransactionRequested(
            id: transaction.id,
            payload: payload,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => WalletsBloc()..add(const WalletsLoadRequested())),
        BlocProvider(create: (context) => GoalsBloc()..add(const GoalsLoadRequested())),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                _showMessage(state.errorMessage!);
                context.read<AuthBloc>().add(const AuthClearMessageRequested());
              }
              if (state.successMessage != null) {
                _showMessage(state.successMessage!);
                if (state.successMessage == 'Đổi mật khẩu thành công' || state.successMessage!.contains('mật khẩu')) {
                  _oldPasswordController.clear();
                  _newPasswordController.clear();
                }
                context.read<AuthBloc>().add(const AuthClearMessageRequested());
              }
            },
          ),
          BlocListener<HomeBloc, HomeState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage ||
                previous.mutationSuccessMessage != current.mutationSuccessMessage ||
                previous.profile != current.profile,
            listener: (context, state) {
              if (state.errorMessage != null) {
                _showMessage(state.errorMessage!);
                context.read<HomeBloc>().add(const HomeClearMessageRequested());
              }
              if (state.mutationSuccessMessage != null) {
                _showMessage(state.mutationSuccessMessage!);
                context.read<HomeBloc>().add(const HomeClearMessageRequested());
              }
              final profile = state.profile;
              if (profile != null && _usernameController.text.isEmpty) {
                _usernameController.text = profile.username;
                _emailController.text = profile.email;
              }
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return BlocBuilder<HomeBloc, HomeState>(
              builder: (context, homeState) {
                final isBusy = homeState.isLoading || homeState.isMutating;

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Expense Tracker'),
                    actions: [
                      IconButton(
                        tooltip: 'Tải lại',
                        onPressed: isBusy
                            ? null
                            : () {
                                context.read<HomeBloc>().add(const HomeLoadRequested());
                                context.read<WalletsBloc>().add(const WalletsLoadRequested());
                                context.read<GoalsBloc>().add(const GoalsLoadRequested());
                              },
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: 'Đăng xuất',
                        onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: homeState.isLoading && homeState.dashboard == null
                        ? const Center(child: CircularProgressIndicator())
                        : IndexedStack(
                            index: _selectedIndex,
                            children: [
                              PageShell(
                                child: Column(
                                  children: [
                                    DashboardView(state: homeState),
                                    const SizedBox(height: 32),
                                    const Divider(),
                                    const SizedBox(height: 24),
                                    TransactionsView(
                                      state: homeState,
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
                                      onEdit: _showTransactionForm,
                                      onDelete: _deleteTransaction,
                                    ),
                                  ],
                                ),
                              ),
                              const PageShell(
                                child: WalletsView(),
                              ),
                              const PageShell(
                                child: GoalsView(),
                              ),
                              PageShell(
                                child: ProfileView(
                                  authState: authState,
                                  homeState: homeState,
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
                  floatingActionButton: _selectedIndex == 0
                      ? FloatingActionButton(
                          tooltip: 'Thêm giao dịch',
                          onPressed: isBusy ? null : () => _showTransactionForm(),
                          child: const Icon(Icons.add),
                        )
                      : null,
                  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: Icon(Icons.account_balance_wallet),
                        label: 'Ví',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.track_changes_outlined),
                        selectedIcon: Icon(Icons.track_changes),
                        label: 'Mục tiêu',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Hồ sơ',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
