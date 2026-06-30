part of 'wallets_bloc.dart';

abstract class WalletsEvent {
  const WalletsEvent();
}

class WalletsLoadRequested extends WalletsEvent {
  const WalletsLoadRequested();
}

class WalletCreateRequested extends WalletsEvent {
  const WalletCreateRequested({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}

class WalletSelectRequested extends WalletsEvent {
  const WalletSelectRequested(this.walletId);

  final int walletId;
}

class WalletInviteMemberRequested extends WalletsEvent {
  const WalletInviteMemberRequested({
    required this.walletId,
    required this.email,
  });

  final int walletId;
  final String email;
}

class WalletsClearMessageRequested extends WalletsEvent {
  const WalletsClearMessageRequested();
}
