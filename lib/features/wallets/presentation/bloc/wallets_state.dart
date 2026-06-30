part of 'wallets_bloc.dart';

enum WalletsStatus { initial, loading, success, failure }

class WalletsState {
  const WalletsState({
    this.status = WalletsStatus.initial,
    this.wallets = const [],
    this.selectedWallet,
    this.errorMessage,
    this.successMessage,
    this.isMutating = false,
    this.isDetailLoading = false,
  });

  final WalletsStatus status;
  final List<WalletModel> wallets;
  final WalletModel? selectedWallet;
  final String? errorMessage;
  final String? successMessage;
  final bool isMutating;
  final bool isDetailLoading;

  WalletsState copyWith({
    WalletsStatus? status,
    List<WalletModel>? wallets,
    WalletModel? selectedWallet,
    String? errorMessage,
    String? successMessage,
    bool? isMutating,
    bool? isDetailLoading,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WalletsState(
      status: status ?? this.status,
      wallets: wallets ?? this.wallets,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isMutating: isMutating ?? this.isMutating,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
    );
  }
}
