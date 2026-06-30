import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../../dashboard/data/models/category_analytics_model.dart';
import '../../../dashboard/data/models/dashboard_summary_model.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../transactions/data/datasources/transactions_remote_data_source.dart';
import '../../../transactions/data/models/transaction_model.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    ProfileRemoteDataSource? profileRemoteDataSource,
    DashboardRemoteDataSource? dashboardRemoteDataSource,
    TransactionsRemoteDataSource? transactionsRemoteDataSource,
  })  : _profileRemoteDataSource =
            profileRemoteDataSource ?? ProfileRemoteDataSourceImpl(),
        _dashboardRemoteDataSource =
            dashboardRemoteDataSource ?? DashboardRemoteDataSourceImpl(),
        _transactionsRemoteDataSource =
            transactionsRemoteDataSource ?? TransactionsRemoteDataSourceImpl(),
        super(const HomeState()) {
    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeSearchTransactionsRequested>(_onSearchTransactionsRequested);
    on<HomeUpdateProfileRequested>(_onUpdateProfileRequested);
    on<HomeCreateTransactionRequested>(_onCreateTransactionRequested);
    on<HomeUpdateTransactionRequested>(_onUpdateTransactionRequested);
    on<HomeDeleteTransactionRequested>(_onDeleteTransactionRequested);
    on<HomeClearMessageRequested>(_onClearMessageRequested);
  }

  final ProfileRemoteDataSource _profileRemoteDataSource;
  final DashboardRemoteDataSource _dashboardRemoteDataSource;
  final TransactionsRemoteDataSource _transactionsRemoteDataSource;

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    AppLogger.info('[HomeBloc] HomeLoadRequested start');
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final results = await Future.wait([
        _profileRemoteDataSource.getProfile(),
        _dashboardRemoteDataSource.getDashboard(),
        _dashboardRemoteDataSource.getCategoryAnalytics(),
        state.filter.isEmpty
            ? _transactionsRemoteDataSource.getTransactions()
            : _transactionsRemoteDataSource.searchTransactions(filter: state.filter),
      ]);

      emit(state.copyWith(
        isLoading: false,
        profile: results[0] as UserProfileModel,
        dashboard: results[1] as DashboardSummaryModel,
        categoryAnalytics: results[2] as List<CategoryAnalyticsModel>,
        transactions: results[3] as List<TransactionModel>,
      ));
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeBloc] HomeLoadRequested AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      emit(state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeBloc] HomeLoadRequested unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    } finally {
      AppLogger.info('[HomeBloc] HomeLoadRequested done');
    }
  }

  Future<void> _onSearchTransactionsRequested(
    HomeSearchTransactionsRequested event,
    Emitter<HomeState> emit,
  ) async {
    AppLogger.debug(
      '[HomeBloc] HomeSearchTransactionsRequested filter=${event.filter.toQueryParameters()}',
    );
    emit(state.copyWith(
      filter: event.filter,
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final List<TransactionModel> transactions;
      final hasKeyword = event.filter.keyword != null && event.filter.keyword!.trim().isNotEmpty;

      if (event.filter.isEmpty) {
        transactions = await _transactionsRemoteDataSource.getTransactions();
      } else if (hasKeyword) {
        // Có từ khóa -> gọi API search của server (với tham số 'q')
        final rawTransactions = await _transactionsRemoteDataSource.searchTransactions(
          filter: event.filter,
        );
        transactions = rawTransactions.where((t) {
          if (event.filter.category != null && event.filter.category!.trim().isNotEmpty) {
            final filterCat = event.filter.category!.trim().toLowerCase();
            if (!t.category.toLowerCase().contains(filterCat)) {
              return false;
            }
          }
          if (event.filter.type != null) {
            if (t.type != event.filter.type) {
              return false;
            }
          }
          if (event.filter.startDate != null) {
            if (t.date != null && t.date!.isBefore(event.filter.startDate!)) {
              return false;
            }
          }
          if (event.filter.endDate != null) {
            if (t.date != null && t.date!.isAfter(event.filter.endDate!)) {
              return false;
            }
          }
          return true;
        }).toList();
      } else {
        // Không có từ khóa tìm kiếm nhưng có lọc theo category, type hoặc date range
        // -> Gọi getTransactions để lấy tất cả giao dịch, sau đó lọc ở client-side
        final rawTransactions = await _transactionsRemoteDataSource.getTransactions();
        transactions = rawTransactions.where((t) {
          if (event.filter.category != null && event.filter.category!.trim().isNotEmpty) {
            final filterCat = event.filter.category!.trim().toLowerCase();
            if (!t.category.toLowerCase().contains(filterCat)) {
              return false;
            }
          }
          if (event.filter.type != null) {
            if (t.type != event.filter.type) {
              return false;
            }
          }
          if (event.filter.startDate != null) {
            if (t.date != null && t.date!.isBefore(event.filter.startDate!)) {
              return false;
            }
          }
          if (event.filter.endDate != null) {
            if (t.date != null && t.date!.isAfter(event.filter.endDate!)) {
              return false;
            }
          }
          return true;
        }).toList();
      }
      emit(state.copyWith(
        isMutating: false,
        transactions: transactions,
      ));
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeBloc] HomeSearchTransactionsRequested AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeBloc] HomeSearchTransactionsRequested unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onUpdateProfileRequested(
    HomeUpdateProfileRequested event,
    Emitter<HomeState> emit,
  ) async {
    AppLogger.debug(
      '[HomeBloc] HomeUpdateProfileRequested username=${event.username} email=${event.email}',
    );
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _profileRemoteDataSource.updateProfile(
        username: event.username,
        email: event.email,
      );
      emit(state.copyWith(
        isMutating: false,
        profile: result.profile,
        mutationSuccessMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeBloc] HomeUpdateProfileRequested AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeBloc] HomeUpdateProfileRequested unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onCreateTransactionRequested(
    HomeCreateTransactionRequested event,
    Emitter<HomeState> emit,
  ) async {
    AppLogger.debug(
      '[HomeBloc] HomeCreateTransactionRequested payload=${event.payload.toJson()}',
    );
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _transactionsRemoteDataSource.createTransaction(
        payload: event.payload,
      );

      final results = await Future.wait([
        _dashboardRemoteDataSource.getDashboard(),
        _dashboardRemoteDataSource.getCategoryAnalytics(),
        state.filter.isEmpty
            ? _transactionsRemoteDataSource.getTransactions()
            : _transactionsRemoteDataSource.searchTransactions(filter: state.filter),
      ]);

      emit(state.copyWith(
        isMutating: false,
        dashboard: results[0] as DashboardSummaryModel,
        categoryAnalytics: results[1] as List<CategoryAnalyticsModel>,
        transactions: results[2] as List<TransactionModel>,
        mutationSuccessMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeBloc] HomeCreateTransactionRequested AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeBloc] HomeCreateTransactionRequested unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onUpdateTransactionRequested(
    HomeUpdateTransactionRequested event,
    Emitter<HomeState> emit,
  ) async {
    AppLogger.debug(
      '[HomeBloc] HomeUpdateTransactionRequested id=${event.id} payload=${event.payload.toJson()}',
    );
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final result = await _transactionsRemoteDataSource.updateTransaction(
        id: event.id,
        payload: event.payload,
      );

      final results = await Future.wait([
        _dashboardRemoteDataSource.getDashboard(),
        _dashboardRemoteDataSource.getCategoryAnalytics(),
        state.filter.isEmpty
            ? _transactionsRemoteDataSource.getTransactions()
            : _transactionsRemoteDataSource.searchTransactions(filter: state.filter),
      ]);

      emit(state.copyWith(
        isMutating: false,
        dashboard: results[0] as DashboardSummaryModel,
        categoryAnalytics: results[1] as List<CategoryAnalyticsModel>,
        transactions: results[2] as List<TransactionModel>,
        mutationSuccessMessage: result.message,
      ));
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeBloc] HomeUpdateTransactionRequested AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeBloc] HomeUpdateTransactionRequested unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  Future<void> _onDeleteTransactionRequested(
    HomeDeleteTransactionRequested event,
    Emitter<HomeState> emit,
  ) async {
    AppLogger.debug('[HomeBloc] HomeDeleteTransactionRequested id=${event.id}');
    emit(state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await _transactionsRemoteDataSource.deleteTransaction(
        id: event.id,
      );

      final results = await Future.wait([
        _dashboardRemoteDataSource.getDashboard(),
        _dashboardRemoteDataSource.getCategoryAnalytics(),
        state.filter.isEmpty
            ? _transactionsRemoteDataSource.getTransactions()
            : _transactionsRemoteDataSource.searchTransactions(filter: state.filter),
      ]);

      emit(state.copyWith(
        isMutating: false,
        dashboard: results[0] as DashboardSummaryModel,
        categoryAnalytics: results[1] as List<CategoryAnalyticsModel>,
        transactions: results[2] as List<TransactionModel>,
        mutationSuccessMessage: message,
      ));
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeBloc] HomeDeleteTransactionRequested AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: error.message,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeBloc] HomeDeleteTransactionRequested unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isMutating: false,
        errorMessage: 'Không thể kết nối máy chủ',
      ));
    }
  }

  void _onClearMessageRequested(
    HomeClearMessageRequested event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}
