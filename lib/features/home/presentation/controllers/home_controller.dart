import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../../dashboard/data/models/category_analytics_model.dart';
import '../../../dashboard/data/models/dashboard_summary_model.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../transactions/data/datasources/transactions_remote_data_source.dart';
import '../../../transactions/data/models/transaction_model.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    ProfileRemoteDataSource? profileRemoteDataSource,
    DashboardRemoteDataSource? dashboardRemoteDataSource,
    TransactionsRemoteDataSource? transactionsRemoteDataSource,
  })  : _profileRemoteDataSource =
            profileRemoteDataSource ?? ProfileRemoteDataSourceImpl(),
        _dashboardRemoteDataSource =
            dashboardRemoteDataSource ?? DashboardRemoteDataSourceImpl(),
        _transactionsRemoteDataSource =
            transactionsRemoteDataSource ?? TransactionsRemoteDataSourceImpl();

  final ProfileRemoteDataSource _profileRemoteDataSource;
  final DashboardRemoteDataSource _dashboardRemoteDataSource;
  final TransactionsRemoteDataSource _transactionsRemoteDataSource;

  UserProfileModel? _profile;
  DashboardSummaryModel? _dashboard;
  List<CategoryAnalyticsModel> _categoryAnalytics = const [];
  List<TransactionModel> _transactions = const [];
  TransactionSearchFilter _filter = const TransactionSearchFilter();
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  DashboardSummaryModel? get dashboard => _dashboard;
  List<CategoryAnalyticsModel> get categoryAnalytics => _categoryAnalytics;
  List<TransactionModel> get transactions => _transactions;
  TransactionSearchFilter get filter => _filter;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    AppLogger.info('[HomeController] load() start');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        loadProfile(notify: false),
        loadDashboard(notify: false),
        loadTransactions(notify: false),
      ]);
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeController] load() AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeController] load() unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Không thể kết nối máy chủ';
    } finally {
      _isLoading = false;
      AppLogger.info('[HomeController] load() done');
      notifyListeners();
    }
  }

  Future<void> loadProfile({bool notify = true}) async {
    AppLogger.debug('[HomeController] loadProfile()');
    _profile = await _profileRemoteDataSource.getProfile();
    if (notify) notifyListeners();
  }

  Future<void> loadDashboard({bool notify = true}) async {
    AppLogger.debug('[HomeController] loadDashboard()');
    final results = await Future.wait([
      _dashboardRemoteDataSource.getDashboard(),
      _dashboardRemoteDataSource.getCategoryAnalytics(),
    ]);

    _dashboard = results[0] as DashboardSummaryModel;
    _categoryAnalytics = results[1] as List<CategoryAnalyticsModel>;
    if (notify) notifyListeners();
  }

  Future<void> loadTransactions({bool notify = true}) async {
    final filter = _filter;
    AppLogger.debug(
      '[HomeController] loadTransactions() filter=${filter.toQueryParameters()}',
    );

    if (filter.isEmpty) {
      _transactions = await _transactionsRemoteDataSource.getTransactions();
    } else {
      _transactions = await _transactionsRemoteDataSource.searchTransactions(
        filter: filter,
      );
    }

    if (notify) notifyListeners();
  }

  Future<void> searchTransactions(TransactionSearchFilter filter) async {
    AppLogger.debug(
      '[HomeController] searchTransactions() filter=${filter.toQueryParameters()}',
    );
    _filter = filter;
    await _guardMutation(loadTransactions);
  }

  Future<String> updateProfile({
    required String username,
    required String email,
  }) async {
    AppLogger.debug(
      '[HomeController] updateProfile() username=$username email=$email',
    );
    return _guardMutation(() async {
      final result = await _profileRemoteDataSource.updateProfile(
        username: username,
        email: email,
      );
      _profile = result.profile;
      return result.message;
    });
  }

  Future<String> createTransaction(TransactionPayload payload) async {
    AppLogger.debug(
      '[HomeController] createTransaction() payload=${payload.toJson()}',
    );
    return _guardMutation(() async {
      final result = await _transactionsRemoteDataSource.createTransaction(
        payload: payload,
      );
      await _refreshAfterTransactionMutation();
      return result.message;
    });
  }

  Future<String> updateTransaction({
    required int id,
    required TransactionPayload payload,
  }) async {
    AppLogger.debug(
      '[HomeController] updateTransaction() id=$id payload=${payload.toJson()}',
    );
    return _guardMutation(() async {
      final result = await _transactionsRemoteDataSource.updateTransaction(
        id: id,
        payload: payload,
      );
      await _refreshAfterTransactionMutation();
      return result.message;
    });
  }

  Future<String> deleteTransaction(int id) async {
    AppLogger.debug('[HomeController] deleteTransaction() id=$id');
    return _guardMutation(() async {
      final message = await _transactionsRemoteDataSource.deleteTransaction(
        id: id,
      );
      await _refreshAfterTransactionMutation();
      return message;
    });
  }

  Future<void> _refreshAfterTransactionMutation() async {
    await Future.wait([
      loadDashboard(notify: false),
      loadTransactions(notify: false),
    ]);
  }

  Future<T> _guardMutation<T>(Future<T> Function() action) async {
    AppLogger.info('[HomeController] mutation start');
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } on AppException catch (error) {
      AppLogger.error(
        '[HomeController] mutation AppException: '
        '${error.message} status=${error.statusCode}',
        error: error,
      );
      _errorMessage = error.message;
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        '[HomeController] mutation unexpected error',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Không thể kết nối máy chủ';
      rethrow;
    } finally {
      _isMutating = false;
      AppLogger.info('[HomeController] mutation done');
      notifyListeners();
    }
  }
}
