part of 'home_bloc.dart';

abstract class HomeEvent {
  const HomeEvent();
}

class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

class HomeSearchTransactionsRequested extends HomeEvent {
  final TransactionSearchFilter filter;

  const HomeSearchTransactionsRequested(this.filter);
}

class HomeUpdateProfileRequested extends HomeEvent {
  final String username;
  final String email;

  const HomeUpdateProfileRequested({
    required this.username,
    required this.email,
  });
}

class HomeCreateTransactionRequested extends HomeEvent {
  final TransactionPayload payload;

  const HomeCreateTransactionRequested(this.payload);
}

class HomeUpdateTransactionRequested extends HomeEvent {
  final int id;
  final TransactionPayload payload;

  const HomeUpdateTransactionRequested({
    required this.id,
    required this.payload,
  });
}

class HomeDeleteTransactionRequested extends HomeEvent {
  final int id;

  const HomeDeleteTransactionRequested(this.id);
}

class HomeClearMessageRequested extends HomeEvent {
  const HomeClearMessageRequested();
}
