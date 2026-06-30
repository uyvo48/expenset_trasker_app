part of 'home_bloc.dart';

class HomeState {
  final UserProfileModel? profile;
  final DashboardSummaryModel? dashboard;
  final List<CategoryAnalyticsModel> categoryAnalytics;
  final List<TransactionModel> transactions;
  final TransactionSearchFilter filter;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final String? mutationSuccessMessage;

  const HomeState({
    this.profile,
    this.dashboard,
    this.categoryAnalytics = const [],
    this.transactions = const [],
    this.filter = const TransactionSearchFilter(),
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.mutationSuccessMessage,
  });

  HomeState copyWith({
    UserProfileModel? profile,
    DashboardSummaryModel? dashboard,
    List<CategoryAnalyticsModel>? categoryAnalytics,
    List<TransactionModel>? transactions,
    TransactionSearchFilter? filter,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    String? mutationSuccessMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return HomeState(
      profile: profile ?? this.profile,
      dashboard: dashboard ?? this.dashboard,
      categoryAnalytics: categoryAnalytics ?? this.categoryAnalytics,
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mutationSuccessMessage: clearSuccess ? null : (mutationSuccessMessage ?? this.mutationSuccessMessage),
    );
  }
}
