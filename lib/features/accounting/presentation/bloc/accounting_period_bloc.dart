import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/accounting_period.dart';
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

// ─────────────────────────── STATES ───────────────────────────

abstract class AccountingPeriodState {}

class AccountingPeriodInitial extends AccountingPeriodState {}

class AccountingPeriodLoading extends AccountingPeriodState {}

class AccountingPeriodLoaded extends AccountingPeriodState {
  final List<AccountingPeriod> periods;
  final bool isRefreshing;

  AccountingPeriodLoaded({required this.periods, this.isRefreshing = false});

  AccountingPeriodLoaded copyWith({
    List<AccountingPeriod>? periods,
    bool? isRefreshing,
  }) =>
      AccountingPeriodLoaded(
        periods: periods ?? this.periods,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}

class AccountingPeriodError extends AccountingPeriodState {
  final String message;
  AccountingPeriodError(this.message);
}

class AccountingPeriodActionSuccess extends AccountingPeriodState {
  final String messageKey; // localization key
  final List<AccountingPeriod> updatedPeriods;

  AccountingPeriodActionSuccess({
    required this.messageKey,
    required this.updatedPeriods,
  });
}

class AccountingPeriodSuggestionLoaded extends AccountingPeriodState {
  final OpeningBalanceSuggestion suggestion;
  AccountingPeriodSuggestionLoaded(this.suggestion);
}

class AccountingPeriodSuggestionError extends AccountingPeriodState {
  final String message;
  AccountingPeriodSuggestionError(this.message);
}

class AccountingAuditLogsLoaded extends AccountingPeriodState {
  final List<AccountingPeriodAuditLog> logs;
  AccountingAuditLogsLoaded(this.logs);
}

class AccountingPeriodDetailLoaded extends AccountingPeriodState {
  final AccountingPeriod period;
  final bool isRefreshing;

  AccountingPeriodDetailLoaded({
    required this.period,
    this.isRefreshing = false,
  });
}

// ─────────────────────────── BLOC ───────────────────────────

class AccountingPeriodBloc
    extends Bloc<AccountingPeriodEvent, AccountingPeriodState> {
  final AccountingRepository _repository;

  AccountingPeriodBloc({required AccountingRepository repository})
      : _repository = repository,
        super(AccountingPeriodInitial()) {
    on<LoadPeriodsRequested>(_onLoadPeriods);
    on<CreatePeriodRequested>(_onCreatePeriod);
    on<CreateCustomPeriodRequested>(_onCreateCustomPeriod);
    on<FetchSuggestionRequested>(_onFetchSuggestion);
    on<FinalizePeriodRequested>(_onFinalizePeriod);
    on<ReopenPeriodRequested>(_onReopenPeriod);
    on<LoadAuditLogsRequested>(_onLoadAuditLogs);
    on<LoadPeriodDetailRequested>(_onLoadPeriodDetail);
  }

  Future<void> _onLoadPeriods(
    LoadPeriodsRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(AccountingPeriodLoading());

    await _repository.fetchPeriodsSWR(
      locationId: event.locationId,
      onData: (periods, fromCache) {
        if (!isClosed) {
          emit(AccountingPeriodLoaded(
            periods: periods,
            isRefreshing: fromCache,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(AccountingPeriodError(error.toString()));
        }
      },
    );
  }

  Future<void> _onCreatePeriod(
    CreatePeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(AccountingPeriodLoading());
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
      emit(AccountingPeriodActionSuccess(
        messageKey: 'accounting.period_created_success',
        updatedPeriods: updated,
      ));
    } catch (e) {
      emit(AccountingPeriodError(e.toString()));
    }
  }

  Future<void> _onCreateCustomPeriod(
    CreateCustomPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(AccountingPeriodLoading());
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
      emit(AccountingPeriodActionSuccess(
        messageKey: 'accounting.period_created_success',
        updatedPeriods: updated,
      ));
    } catch (e) {
      emit(AccountingPeriodError(e.toString()));
    }
  }

  Future<void> _onFetchSuggestion(
    FetchSuggestionRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    try {
      final suggestion = await _repository.getOpeningBalanceSuggestion(
        locationId: event.locationId,
        periodType: event.periodType,
        year: event.year,
        quarter: event.quarter,
        startDate: event.startDate,
      );
      emit(AccountingPeriodSuggestionLoaded(suggestion));
    } catch (e) {
      emit(AccountingPeriodSuggestionError(e.toString()));
    }
  }

  Future<void> _onFinalizePeriod(
    FinalizePeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(AccountingPeriodLoading());
    try {
      await _repository.finalizePeriod(
        locationId: event.locationId,
        periodId: event.periodId,
      );
      final updated =
          await _repository.fetchPeriodsFromServer(event.locationId);
      emit(AccountingPeriodActionSuccess(
        messageKey: 'accounting.period_finalized_success',
        updatedPeriods: updated,
      ));
    } catch (e) {
      emit(AccountingPeriodError(e.toString()));
    }
  }

  Future<void> _onReopenPeriod(
    ReopenPeriodRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    emit(AccountingPeriodLoading());
    try {
      await _repository.reopenPeriod(
        locationId: event.locationId,
        periodId: event.periodId,
        reason: event.reason,
      );
      final updated =
          await _repository.fetchPeriodsFromServer(event.locationId);
      emit(AccountingPeriodActionSuccess(
        messageKey: 'accounting.period_reopened_success',
        updatedPeriods: updated,
      ));
    } catch (e) {
      emit(AccountingPeriodError(e.toString()));
    }
  }

  Future<void> _onLoadAuditLogs(
    LoadAuditLogsRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    try {
      final logs = await _repository.getAuditLogs(
        locationId: event.locationId,
        periodId: event.periodId,
      );
      emit(AccountingAuditLogsLoaded(logs));
    } catch (e) {
      emit(AccountingPeriodError(e.toString()));
    }
  }

  Future<void> _onLoadPeriodDetail(
    LoadPeriodDetailRequested event,
    Emitter<AccountingPeriodState> emit,
  ) async {
    await _repository.fetchPeriodDetailSWR(
      locationId: event.locationId,
      periodId: event.periodId,
      onData: (period, fromCache) {
        if (!isClosed) {
          emit(AccountingPeriodDetailLoaded(
            period: period,
            isRefreshing: fromCache,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(AccountingPeriodError(error.toString()));
        }
      },
    );
  }
}
