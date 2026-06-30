import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/wallets_remote_data_source.dart';
import '../../data/models/wallet_model.dart';

part 'wallets_event.dart';
part 'wallets_state.dart';

class WalletsBloc extends Bloc<WalletsEvent, WalletsState> {
  WalletsBloc({
    WalletsRemoteDataSource? walletsRemoteDataSource,
  })  : _walletsRemoteDataSource =
            walletsRemoteDataSource ?? WalletsRemoteDataSourceImpl(),
        super(const WalletsState()) {
    on<WalletsLoadRequested>(_onLoadRequested);
    on<WalletCreateRequested>(_onCreateRequested);
    on<WalletSelectRequested>(_onSelectRequested);
    on<WalletInviteMemberRequested>(_onInviteMemberRequested);
    on<WalletsClearMessageRequested>(_onClearMessageRequested);
  }

  final WalletsRemoteDataSource _walletsRemoteDataSource;

  Future<void> _onLoadRequested(
    WalletsLoadRequested event,
    Emitter<WalletsState> emit,
  ) async {
    AppLogger.info('[WalletsBloc] WalletsLoadRequested start');
    emit(state.copyWith(
      status: WalletsStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final wallets = await _walletsRemoteDataSource.getWallets();
      emit(state.copyWith(
        status: WalletsStatus.success,
        wallets: wallets,
      ));
      AppLogger.info('[WalletsBloc] WalletsLoadRequested done walletsCount=${wallets.length}');
    } on AppException catch (error) {
      AppLogger.error('[WalletsBloc] WalletsLoadRequested AppException', error: error);
      emit(state.copyWith(
        status: WalletsStatus.failure,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[WalletsBloc] WalletsLoadRequested unexpected error', error: error);
      emit(state.copyWith(
        status: WalletsStatus.failure,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onCreateRequested(
    WalletCreateRequested event,
    Emitter<WalletsState> emit,
  ) async {
    AppLogger.info('[WalletsBloc] WalletCreateRequested name=${event.name}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _walletsRemoteDataSource.createWallet(
        name: event.name,
        description: event.description,
      );

      final updatedWallets = List<WalletModel>.from(state.wallets)..add(result.wallet);

      emit(state.copyWith(
        isMutating: false,
        wallets: updatedWallets,
        successMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[WalletsBloc] WalletCreateRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[WalletsBloc] WalletCreateRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onSelectRequested(
    WalletSelectRequested event,
    Emitter<WalletsState> emit,
  ) async {
    AppLogger.info('[WalletsBloc] WalletSelectRequested walletId=${event.walletId}');
    emit(state.copyWith(
      isDetailLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final details = await _walletsRemoteDataSource.getWalletDetails(id: event.walletId);
      emit(state.copyWith(
        isDetailLoading: false,
        selectedWallet: details,
      ));
    } on AppException catch (error) {
      AppLogger.error('[WalletsBloc] WalletSelectRequested AppException', error: error);
      emit(state.copyWith(
        isDetailLoading: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[WalletsBloc] WalletSelectRequested unexpected error', error: error);
      emit(state.copyWith(
        isDetailLoading: false,
        errorMessage: 'Không thể tải chi tiết ví',
      ));
    }
  }

  Future<void> _onInviteMemberRequested(
    WalletInviteMemberRequested event,
    Emitter<WalletsState> emit,
  ) async {
    AppLogger.info(
      '[WalletsBloc] WalletInviteMemberRequested walletId=${event.walletId} email=${event.email}',
    );
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _walletsRemoteDataSource.inviteMember(
        walletId: event.walletId,
        email: event.email,
      );

      // Re-fetch wallet details after successful invitation to update members list
      final updatedDetails = await _walletsRemoteDataSource.getWalletDetails(id: event.walletId);

      emit(state.copyWith(
        isMutating: false,
        selectedWallet: updatedDetails,
        successMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error('[WalletsBloc] WalletInviteMemberRequested AppException', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error) {
      AppLogger.error('[WalletsBloc] WalletInviteMemberRequested unexpected error', error: error);
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  void _onClearMessageRequested(
    WalletsClearMessageRequested event,
    Emitter<WalletsState> emit,
  ) {
    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}
