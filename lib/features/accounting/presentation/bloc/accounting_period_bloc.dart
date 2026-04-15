import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../domain/models/accounting_period.dart';
import '../../domain/models/accounting_book.dart';
import '../../data/repositories/accounting_repository.dart';

// ─────────────────────────── EVENTS ───────────────────────────

abstract class AccountingPeriodEvent {}

class LoadPeriodsRequested extends AccountingPeriodEvent {
  final String locationId;
  LoadPeriodsRequested(this.locationId);
}

class CreatePeriodRequested extends AccountingPeriodEvent {
  final String locationId;
  final String periodType; // 'quarter' | 'year'
  final int year;
  final int? quarter;
  final double? openingCashBalance;
  final double? openingBankBalance;
  final bool useSuggestedOpeningBalances;

  CreatePeriodRequested({
    required this.locationId,
    required this.periodType,
    required this.year,
    this.quarter,
    this.openingCashBalance,
    this.openingBankBalance,
    this.useSuggestedOpeningBalances = false,
  });
}

class CreateCustomPeriodRequested extends AccountingPeriodEvent {
  final String locationId;
  final String startDate;
  final String endDate;
  final double? openingCashBalance;
  final double? openingBankBalance;
  final bool useSuggestedOpeningBalances;

  CreateCustomPeriodRequested({
    required this.locationId,
    required this.startDate,
    required this.endDate,
    this.openingCashBalance,
    this.openingBankBalance,
    this.useSuggestedOpeningBalances = false,
  });
}

class FetchSuggestionRequested extends AccountingPeriodEvent {
  final String locationId;
  final String periodType;
  final int? year;
  final int? quarter;
  final String? startDate;

  FetchSuggestionRequested({
    required this.locationId,
    required this.periodType,
    this.year,
    this.quarter,
    this.startDate,
  });
}

class FinalizePeriodRequested extends AccountingPeriodEvent {
  final String locationId;
  final String periodId;
  FinalizePeriodRequested({required this.locationId, required this.periodId});
}

class ReopenPeriodRequested extends AccountingPeriodEvent {
  final String locationId;
  final String periodId;
  final String reason;
  ReopenPeriodRequested({
    required this.locationId,
    required this.periodId,
    required this.reason,
  });
}

class LoadAuditLogsRequested extends AccountingPeriodEvent {
  final String locationId;
  final String periodId;
  LoadAuditLogsRequested({required this.locationId, required this.periodId});
}

class LoadPeriodDetailRequested extends AccountingPeriodEvent {
  final String locationId;
  final String periodId;
  LoadPeriodDetailRequested({required this.locationId, required this.periodId});
}

class CreateBooksRequested extends AccountingPeriodEvent {
  final String locationId;
  final int periodId;
  final int groupNumber;
  final String taxMethod;
  final List<String> templateCodes;

  CreateBooksRequested({
    required this.locationId,
    required this.periodId,
    required this.groupNumber,
    required this.taxMethod,
    required this.templateCodes,
  });
}

class LoadBooksForPeriodRequested extends AccountingPeriodEvent {
  final String locationId;
  final int periodId;

  LoadBooksForPeriodRequested({
    required this.locationId,
    required this.periodId,
  });
}

// ─────────────────────────── STATES ───────────────────────────

enum AccountingPeriodStatus { initial, loading, loaded, error, actionSuccess }

class AccountingPeriodState {
  final List<AccountingPeriod> periods;
  final AccountingPeriod? periodDetail;
  final List<AccountingBook> books;
  final List<AccountingPeriodAuditLog> auditLogs;
  final String? auditLogsPeriodId;
  final OpeningBalanceSuggestion? suggestion;

  final AccountingPeriodStatus status;
  final String? errorMessage;
  final String? actionSuccessKey;

  final bool isListLoading;
  final bool isDetailLoading;
  final bool isBooksLoading;
  final bool isLogsLoading;
  final bool isActionLoading;
  final bool isRefreshing; // from cache flag

  AccountingPeriodState({
    this.periods = const [],
    this.periodDetail,
    this.books = const [],
    this.auditLogs = const [],
    this.auditLogsPeriodId,
    this.suggestion,
    this.status = AccountingPeriodStatus.initial,
    this.errorMessage,
    this.actionSuccessKey,
    this.isListLoading = false,
    this.isDetailLoading = false,
    this.isBooksLoading = false,
    this.isLogsLoading = false,
    this.isActionLoading = false,
    this.isRefreshing = false,
  });

  AccountingPeriodState copyWith({
    List<AccountingPeriod>? periods,
    AccountingPeriod? periodDetail,
    List<AccountingBook>? books,
    List<AccountingPeriodAuditLog>? auditLogs,
    String? auditLogsPeriodId,
    OpeningBalanceSuggestion? suggestion,
    AccountingPeriodStatus? status,
    String? errorMessage,
    String? actionSuccessKey,
    bool? isListLoading,
    bool? isDetailLoading,
    bool? isBooksLoading,
    bool? isLogsLoading,
    bool? isActionLoading,
    bool? isRefreshing,
    bool clearDetail = false,
    bool clearBooks = false,
    bool clearAction = false,
  }) {
    return AccountingPeriodState(
      periods: periods ?? this.periods,
      periodDetail: clearDetail ? null : (periodDetail ?? this.periodDetail),
      books: clearBooks ? const [] : (books ?? this.books),
      auditLogs: auditLogs ?? this.auditLogs,
      auditLogsPeriodId: auditLogsPeriodId ?? this.auditLogsPeriodId,
      suggestion: suggestion ?? this.suggestion,
      status: status ?? this.status,
      errorMessage: errorMessage, // Reset error if not provided
      actionSuccessKey: clearAction
          ? null
          : (actionSuccessKey ?? this.actionSuccessKey),
      isListLoading: isListLoading ?? this.isListLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isBooksLoading: isBooksLoading ?? this.isBooksLoading,
      isLogsLoading: isLogsLoading ?? this.isLogsLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

// ─────────────────────────── BLOC ───────────────────────────

class AccountingPeriodBloc
    extends Bloc<AccountingPeriodEvent, AccountingPeriodState> {
  final AccountingRepository _repository;

  AccountingPeriodBloc({required AccountingRepository repository})
    : _repository = repository,
      super(AccountingPeriodState()) {
    on<LoadPeriodsRequested>(_onLoadPeriods);
    on<CreatePeriodRequested>(_onCreatePeriod);
    on<CreateCustomPeriodRequested>(_onCreateCustomPeriod);
    on<FetchSuggestionRequested>(_onFetchSuggestion);
    on<FinalizePeriodRequested>(_onFinalizePeriod);
    on<ReopenPeriodRequested>(_onReopenPeriod);
    on<LoadAuditLogsRequested>(_onLoadAuditLogs);
    on<LoadPeriodDetailRequested>(_onLoadPeriodDetail);
    on<CreateBooksRequested>(_onCreateBooks);
    on<LoadBooksForPeriodRequested>(_onLoadBooksForPeriod);
  }

  Future<void> _onLoadPeriods(
    LoadPeriodsRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountingPeriodStatus.loading,
        isListLoading: true,
      ),
    );

    await _repository.fetchPeriodsSWR(
      locationId: event.locationId,
      onData: (periods, fromCache) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AccountingPeriodStatus.loaded,
              periods: periods,
              isListLoading: false,
              isRefreshing: fromCache,
            ),
          );
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AccountingPeriodStatus.error,
              errorMessage: ApiErrorMessageParser.parse(error),
              isListLoading: false,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCreatePeriod(
    CreatePeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountingPeriodStatus.loading,
        isActionLoading: true,
        clearAction: true,
      ),
    );
    try {
      await _repository.createPeriod(
        locationId: event.locationId,
        periodType: event.periodType,
        year: event.year,
        quarter: event.quarter,
        openingCashBalance: event.openingCashBalance,
        openingBankBalance: event.openingBankBalance,
        useSuggestedOpeningBalances: event.useSuggestedOpeningBalances,
      );
      final updated = await _repository.fetchPeriodsFromServer(
        event.locationId,
      );
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.actionSuccess,
          actionSuccessKey: 'accounting.period_created_success',
          periods: updated,
          isActionLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: ApiErrorMessageParser.parse(e),
          isActionLoading: false,
        ),
      );
    }
  }

  Future<void> _onCreateCustomPeriod(
    CreateCustomPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountingPeriodStatus.loading,
        isActionLoading: true,
        clearAction: true,
      ),
    );
    try {
      await _repository.createCustomPeriod(
        locationId: event.locationId,
        startDate: event.startDate,
        endDate: event.endDate,
        openingCashBalance: event.openingCashBalance,
        openingBankBalance: event.openingBankBalance,
        useSuggestedOpeningBalances: event.useSuggestedOpeningBalances,
      );
      final updated = await _repository.fetchPeriodsFromServer(
        event.locationId,
      );
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.actionSuccess,
          actionSuccessKey: 'accounting.period_created_success',
          periods: updated,
          isActionLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: ApiErrorMessageParser.parse(e),
          isActionLoading: false,
        ),
      );
    }
  }

  Future<void> _onFetchSuggestion(
    FetchSuggestionRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    // Note: This operation sets a temporary suggestion field
    try {
      final suggestion = await _repository.getOpeningBalanceSuggestion(
        locationId: event.locationId,
        periodType: event.periodType,
        year: event.year,
        quarter: event.quarter,
        startDate: event.startDate,
      );
      emit(state.copyWith(suggestion: suggestion));
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _onFinalizePeriod(
    FinalizePeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountingPeriodStatus.loading,
        isActionLoading: true,
        clearAction: true,
      ),
    );
    try {
      await _repository.finalizePeriod(
        locationId: event.locationId,
        periodId: event.periodId,
      );
      final updated = await _repository.fetchPeriodsFromServer(
        event.locationId,
      );

      // Refresh period detail so bottom sheet reflects the new status
      AccountingPeriod? refreshedDetail;
      try {
        refreshedDetail = await _repository.getPeriodDetail(
          locationId: event.locationId,
          periodId: event.periodId,
        );
      } catch (_) {}

      emit(
        state.copyWith(
          status: AccountingPeriodStatus.actionSuccess,
          actionSuccessKey: 'accounting.period_finalized_success',
          periods: updated,
          periodDetail: refreshedDetail,
          isActionLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: ApiErrorMessageParser.parse(e),
          isActionLoading: false,
        ),
      );
    }
  }

  Future<void> _onReopenPeriod(
    ReopenPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountingPeriodStatus.loading,
        isActionLoading: true,
        clearAction: true,
      ),
    );
    try {
      await _repository.reopenPeriod(
        locationId: event.locationId,
        periodId: event.periodId,
        reason: event.reason,
      );
      final updated = await _repository.fetchPeriodsFromServer(
        event.locationId,
      );

      // Also refresh period detail so the bottom sheet reflects the new status
      AccountingPeriod? refreshedDetail;
      try {
        refreshedDetail = await _repository.getPeriodDetail(
          locationId: event.locationId,
          periodId: event.periodId,
        );
      } catch (_) {
        // Non-critical — the period list is enough to show success
      }

      emit(
        state.copyWith(
          status: AccountingPeriodStatus.actionSuccess,
          actionSuccessKey: 'accounting.period_reopened_success',
          periods: updated,
          periodDetail: refreshedDetail,
          isActionLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: ApiErrorMessageParser.parse(e),
          isActionLoading: false,
        ),
      );
    }
  }

  Future<void> _onLoadAuditLogs(
    LoadAuditLogsRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    final shouldClearLogs = state.auditLogsPeriodId != event.periodId;
    emit(
      state.copyWith(
        isLogsLoading: true,
        auditLogsPeriodId: event.periodId,
        auditLogs: shouldClearLogs ? const <AccountingPeriodAuditLog>[] : null,
        errorMessage: null,
      ),
    );

    var hasDeliveredData = false;
    await _repository.fetchAuditLogsSWR(
      locationId: event.locationId,
      periodId: event.periodId,
      onData: (logs, fromCache) {
        hasDeliveredData = true;
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AccountingPeriodStatus.loaded,
              auditLogs: logs,
              auditLogsPeriodId: event.periodId,
              isLogsLoading: false,
              isRefreshing: fromCache,
              errorMessage: null,
            ),
          );
        }
      },
      onError: (error) {
        if (isClosed) return;
        if (!hasDeliveredData) {
          emit(
            state.copyWith(
              status: AccountingPeriodStatus.error,
              errorMessage: ApiErrorMessageParser.parse(error),
              isLogsLoading: false,
              isRefreshing: false,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            isLogsLoading: false,
            isRefreshing: false,
          ),
        );
      },
    );
  }

  Future<void> _onLoadPeriodDetail(
    LoadPeriodDetailRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(isDetailLoading: true));
    await _repository.fetchPeriodDetailSWR(
      locationId: event.locationId,
      periodId: event.periodId,
      onData: (period, fromCache) {
        if (!isClosed) {
          emit(
            state.copyWith(
              periodDetail: period,
              isDetailLoading: false,
              isRefreshing: fromCache,
            ),
          );
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AccountingPeriodStatus.error,
              errorMessage: ApiErrorMessageParser.parse(error),
              isDetailLoading: false,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCreateBooks(
    CreateBooksRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountingPeriodStatus.loading,
        isActionLoading: true,
        clearAction: true,
      ),
    );
    try {
      final response = await _repository.createBooksForPeriod(
        locationId: event.locationId,
        body: {
          'periodId': event.periodId,
          'groupNumber': event.groupNumber,
          'taxMethod': event.taxMethod,
          'templateCodes': event.templateCodes,
        },
      );

      if (response.success && response.createdBooks.isNotEmpty) {
        emit(
          state.copyWith(
            status: AccountingPeriodStatus.actionSuccess,
            actionSuccessKey: 'accounting.books_created_success',
            books: response.createdBooks,
            isActionLoading: false,
          ),
        );
        // Refresh period list after successful book creation
        await _repository.fetchPeriodsFromServer(event.locationId);
      } else {
        emit(
          state.copyWith(
            status: AccountingPeriodStatus.error,
            errorMessage: 'Failed to create accounting books',
            isActionLoading: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: ApiErrorMessageParser.parse(e),
          isActionLoading: false,
        ),
      );
    }
  }

  Future<void> _onLoadBooksForPeriod(
    LoadBooksForPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(isBooksLoading: true));
    try {
      await _repository.fetchBooksForPeriodSWR(
        locationId: event.locationId,
        periodId: event.periodId.toString(),
        onData: (fetchedBooks, fromCache) {
          if (!isClosed) {
            emit(
              state.copyWith(
                books: fetchedBooks,
                isBooksLoading: false,
                isRefreshing: fromCache,
              ),
            );
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: AccountingPeriodStatus.error,
                errorMessage: ApiErrorMessageParser.parse(error),
                isBooksLoading: false,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AccountingPeriodStatus.error,
            errorMessage: ApiErrorMessageParser.parse(e),
            isBooksLoading: false,
          ),
        );
      }
    }
  }
}
