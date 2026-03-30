import 'package:flutter_bloc/flutter_bloc.dart';
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
  final OpeningBalanceSuggestion? suggestion;

  final AccountingPeriodStatus status;
  final String? errorMessage;
  final String? actionSuccessKey;

  final bool isListLoading;
  final bool isDetailLoading;
  final bool isBooksLoading;
  final bool isLogsLoading;
  final bool isActionLoading;
  final bool isListRefreshing; 
  final bool isDetailRefreshing;
  final bool isBooksRefreshing;

  AccountingPeriodState({
    this.periods = const [],
    this.periodDetail,
    this.books = const [],
    this.auditLogs = const [],
    this.suggestion,
    this.status = AccountingPeriodStatus.initial,
    this.errorMessage,
    this.actionSuccessKey,
    this.isListLoading = false,
    this.isDetailLoading = false,
    this.isBooksLoading = false,
    this.isLogsLoading = false,
    this.isActionLoading = false,
    this.isListRefreshing = false,
    this.isDetailRefreshing = false,
    this.isBooksRefreshing = false,
  });

  AccountingPeriodState copyWith({
    List<AccountingPeriod>? periods,
    AccountingPeriod? periodDetail,
    List<AccountingBook>? books,
    List<AccountingPeriodAuditLog>? auditLogs,
    OpeningBalanceSuggestion? suggestion,
    AccountingPeriodStatus? status,
    String? errorMessage,
    String? actionSuccessKey,
    bool? isListLoading,
    bool? isDetailLoading,
    bool? isBooksLoading,
    bool? isLogsLoading,
    bool? isActionLoading,
    bool? isListRefreshing,
    bool? isDetailRefreshing,
    bool? isBooksRefreshing,
    bool clearDetail = false,
    bool clearBooks = false,
    bool clearAction = false,
  }) {
    return AccountingPeriodState(
      periods: periods ?? this.periods,
      periodDetail: clearDetail ? null : (periodDetail ?? this.periodDetail),
      books: clearBooks ? const [] : (books ?? this.books),
      auditLogs: auditLogs ?? this.auditLogs,
      suggestion: suggestion ?? this.suggestion,
      status: status ?? this.status,
      errorMessage: errorMessage, // Reset error if not provided
      actionSuccessKey: clearAction ? null : (actionSuccessKey ?? this.actionSuccessKey),
      isListLoading: isListLoading ?? this.isListLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isBooksLoading: isBooksLoading ?? this.isBooksLoading,
      isLogsLoading: isLogsLoading ?? this.isLogsLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isListRefreshing: isListRefreshing ?? this.isListRefreshing,
      isDetailRefreshing: isDetailRefreshing ?? this.isDetailRefreshing,
      isBooksRefreshing: isBooksRefreshing ?? this.isBooksRefreshing,
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
    emit(state.copyWith(
      status: AccountingPeriodStatus.loading,
      isListLoading: true,
    ));

    await _repository.fetchPeriodsSWR(
      locationId: event.locationId,
      onData: (periods, fromCache) {
        if (!isClosed) {
          emit(state.copyWith(
            status: AccountingPeriodStatus.loaded,
            periods: periods,
            isListLoading: false,
            isListRefreshing: fromCache,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(state.copyWith(
            status: AccountingPeriodStatus.error,
            errorMessage: error.toString(),
            isListLoading: false,
          ));
        }
      },
    );
  }

  Future<void> _onCreatePeriod(
    CreatePeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(
      status: AccountingPeriodStatus.loading,
      isActionLoading: true,
      clearAction: true,
    ));
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
      final updated =
          await _repository.fetchPeriodsFromServer(event.locationId);
      emit(state.copyWith(
        status: AccountingPeriodStatus.actionSuccess,
        actionSuccessKey: 'accounting.period_created_success',
        periods: updated,
        isActionLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
        isActionLoading: false,
      ));
    }
  }

  Future<void> _onCreateCustomPeriod(
    CreateCustomPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(
      status: AccountingPeriodStatus.loading,
      isActionLoading: true,
      clearAction: true,
    ));
    try {
      await _repository.createCustomPeriod(
        locationId: event.locationId,
        startDate: event.startDate,
        endDate: event.endDate,
        openingCashBalance: event.openingCashBalance,
        openingBankBalance: event.openingBankBalance,
        useSuggestedOpeningBalances: event.useSuggestedOpeningBalances,
      );
      final updated =
          await _repository.fetchPeriodsFromServer(event.locationId);
      emit(state.copyWith(
        status: AccountingPeriodStatus.actionSuccess,
        actionSuccessKey: 'accounting.period_created_success',
        periods: updated,
        isActionLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
        isActionLoading: false,
      ));
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
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFinalizePeriod(
    FinalizePeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(
      status: AccountingPeriodStatus.loading,
      isActionLoading: true,
      clearAction: true,
    ));
    try {
      await _repository.finalizePeriod(
        locationId: event.locationId,
        periodId: event.periodId,
      );
      final updated =
          await _repository.fetchPeriodsFromServer(event.locationId);
      emit(state.copyWith(
        status: AccountingPeriodStatus.actionSuccess,
        actionSuccessKey: 'accounting.period_finalized_success',
        periods: updated,
        isActionLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
        isActionLoading: false,
      ));
    }
  }

  Future<void> _onReopenPeriod(
    ReopenPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(
      status: AccountingPeriodStatus.loading,
      isActionLoading: true,
      clearAction: true,
    ));
    try {
      await _repository.reopenPeriod(
        locationId: event.locationId,
        periodId: event.periodId,
        reason: event.reason,
      );
      final updated =
          await _repository.fetchPeriodsFromServer(event.locationId);
      emit(state.copyWith(
        status: AccountingPeriodStatus.actionSuccess,
        actionSuccessKey: 'accounting.period_reopened_success',
        periods: updated,
        isActionLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
        isActionLoading: false,
      ));
    }
  }

  Future<void> _onLoadAuditLogs(
    LoadAuditLogsRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(isLogsLoading: true));
    try {
      final logs = await _repository.getAuditLogs(
        locationId: event.locationId,
        periodId: event.periodId,
      );
      emit(state.copyWith(
        auditLogs: logs,
        isLogsLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
        isLogsLoading: false,
      ));
    }
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
          emit(state.copyWith(
            periodDetail: period,
            isDetailLoading: false,
            isDetailRefreshing: fromCache,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(state.copyWith(
            status: AccountingPeriodStatus.error,
            errorMessage: error.toString(),
            isDetailLoading: false,
          ));
        }
      },
    );
  }

  Future<void> _onCreateBooks(
    CreateBooksRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(state.copyWith(
      status: AccountingPeriodStatus.loading,
      isActionLoading: true,
      clearAction: true,
    ));
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
        emit(state.copyWith(
          status: AccountingPeriodStatus.actionSuccess,
          actionSuccessKey: 'accounting.books_created_success',
          books: response.createdBooks,
          isActionLoading: false,
        ));
        // Refresh period list after successful book creation
        await _repository.fetchPeriodsFromServer(event.locationId);
      } else {
        emit(state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: 'Failed to create accounting books',
          isActionLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AccountingPeriodStatus.error,
        errorMessage: e.toString(),
        isActionLoading: false,
      ));
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
            emit(state.copyWith(
              books: fetchedBooks,
              isBooksLoading: false,
              isBooksRefreshing: fromCache,
            ));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(state.copyWith(
              status: AccountingPeriodStatus.error,
              errorMessage: error.toString(),
              isBooksLoading: false,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: AccountingPeriodStatus.error,
          errorMessage: e.toString(),
          isBooksLoading: false,
        ));
      }
    }
  }
}

