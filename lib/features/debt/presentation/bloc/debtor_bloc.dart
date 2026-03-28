import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/context/business_context.dart';
import '../../data/debtor_repository.dart';
import '../../data/models/debtor_models.dart';
import '../../domain/entities/debtor_entity.dart';
import 'debtor_event.dart';
import 'debtor_state.dart';

class DebtorBloc extends Bloc<DebtorEvent, DebtorState> {
  final DebtorRepository repository;

  DebtorBloc({required this.repository}) : super(const DebtorState()) {
    on<LoadDebtorsRequested>(_onLoadDebtorsRequested);
    on<RefreshDebtorsRequested>(_onRefreshDebtorsRequested);
    on<ToggleDebtorStatusRequested>(_onToggleDebtorStatusRequested);
    on<DeleteDebtorRequested>(_onDeleteDebtorRequested);
    on<LoadActiveDebtorsByLocationRequested>(_onLoadActiveDebtorsByLocation);
    on<CreateDebtorRequested>(_onCreateDebtorRequested);
    on<UpdateDebtorRequested>(_onUpdateDebtorRequested);
    on<RecordDebtAdjustmentRequested>(_onRecordDebtAdjustmentRequested);
    on<LoadDebtorDetailRequested>(_onLoadDebtorDetailRequested);
    on<LoadDebtPaymentHistoryRequested>(_onLoadDebtPaymentHistoryRequested);
    on<ResetDebtors>(_onResetDebtors);
  }

  List<DebtorEntity> _debtors = <DebtorEntity>[];

  String _buildDebtorCacheKey({
    required List<int>? locationIds,
    required String? search,
    required bool? isActive,
    required int pageNumber,
    required int pageSize,
  }) {
    final businessId = BusinessContext().currentBusinessId ?? 'all';
    final locationKey = (locationIds == null || locationIds.isEmpty)
        ? 'all'
        : locationIds.join('-');
    final searchKey = (search ?? '').trim();
    final activeKey = isActive == null ? 'all' : (isActive ? '1' : '0');
    return 'cache_debtors_${businessId}_${locationKey}_${searchKey}_${activeKey}_${pageNumber}_$pageSize';
  }

  Future<void> _onLoadDebtorsRequested(
    LoadDebtorsRequested event,
    Emitter<DebtorState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DebtorStatus.loading,
        errorMessage: null,
        search: event.search,
        isActive: event.isActive,
        businessLocationIds: event.businessLocationIds,
      ),
    );

    final resolvedLocationIds = _resolveBusinessLocationIds(
      explicit: event.businessLocationIds,
    );

    final cacheKey = _buildDebtorCacheKey(
      locationIds: resolvedLocationIds,
      search: event.search,
      isActive: event.isActive,
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
    );

    await CacheManager().fetchWithSWR<DebtorListResult>(
      key: cacheKey,
      fetcher: ({cancelToken}) {
        return repository.getDebtors(
          businessLocationIds: resolvedLocationIds,
          search: event.search,
          isActive: event.isActive,
          pageNumber: event.pageNumber,
          pageSize: event.pageSize,
        );
      },
      fromJson: DebtorListResult.fromCacheMap,
      toJson: (result) => result.toCacheMap(),
      onData: (result, _) {
        _debtors = result.items;
        emit(
          state.copyWith(
            status: DebtorStatus.success,
            debtors: result.items,
            hasReachedMax: !result.hasNextPage,
            currentPage: result.pageNumber,
            totalCount: result.totalCount,
            errorMessage: null,
          ),
        );
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: DebtorStatus.failure,
            errorMessage: _parseErrorMessage(error),
          ),
        );
      },
    );
  }

  Future<void> _onRefreshDebtorsRequested(
    RefreshDebtorsRequested event,
    Emitter<DebtorState> emit,
  ) async {
    add(
      LoadDebtorsRequested(
        businessLocationIds: state.businessLocationIds,
        search: state.search,
        isActive: state.isActive,
        pageNumber: 1,
      ),
    );
  }

  Future<void> _onToggleDebtorStatusRequested(
    ToggleDebtorStatusRequested event,
    Emitter<DebtorState> emit,
  ) async {
    try {
      await repository.updateDebtorStatus(
        debtorId: event.debtorId,
        isActive: event.isActive,
      );

      _debtors = _debtors.map((debtor) {
        if (debtor.debtorId == event.debtorId) {
          return debtor.copyWith(isActive: event.isActive);
        }
        return debtor;
      }).toList();

      emit(
        state.copyWith(
          status: DebtorStatus.success,
          debtors: _debtors,
          lastMessageCode: event.isActive
              ? 'DEBTOR_STATUS_ACTIVATED'
              : 'DEBTOR_STATUS_DEACTIVATED',
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DebtorStatus.failure,
          errorMessage: _parseErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onDeleteDebtorRequested(
    DeleteDebtorRequested event,
    Emitter<DebtorState> emit,
  ) async {
    try {
      await repository.deleteDebtor(
        debtorId: event.debtorId,
        force: event.force,
      );

      _debtors = _debtors
          .where((debtor) => debtor.debtorId != event.debtorId)
          .toList();

      emit(
        state.copyWith(
          status: DebtorStatus.success,
          debtors: _debtors,
          totalCount: _debtors.length,
          lastMessageCode: 'DEBTOR_DELETED',
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DebtorStatus.failure,
          errorMessage: _parseErrorMessage(e),
          lastMessageCode: 'DEBTOR_DELETE_FAILED',
        ),
      );
    }
  }

  Future<void> _onCreateDebtorRequested(
    CreateDebtorRequested event,
    Emitter<DebtorState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final created = await repository.createDebtor(
        businessLocationId: event.businessLocationId,
        name: event.name,
        phone: event.phone,
        address: event.address,
        notes: event.notes,
        creditLimit: event.creditLimit,
      );

      if (created != null) {
        _debtors = [created, ..._debtors];
      }

      emit(
        state.copyWith(
          status: DebtorStatus.success,
          debtors: _debtors,
          debtorDetail: created ?? state.debtorDetail,
          totalCount: _debtors.length,
          isSubmitting: false,
          lastMessageCode: 'DEBTOR_CREATED',
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DebtorStatus.failure,
          isSubmitting: false,
          errorMessage: _parseErrorMessage(e),
          lastMessageCode: 'DEBTOR_CREATE_FAILED',
        ),
      );
    }
  }

  Future<void> _onUpdateDebtorRequested(
    UpdateDebtorRequested event,
    Emitter<DebtorState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final updated = await repository.updateDebtor(
        debtorId: event.debtorId,
        name: event.name,
        phone: event.phone,
        address: event.address,
        notes: event.notes,
        creditLimit: event.creditLimit,
      );

      if (updated != null) {
        _debtors = _debtors
            .map(
              (debtor) => debtor.debtorId == event.debtorId ? updated : debtor,
            )
            .toList();
      }

      emit(
        state.copyWith(
          status: DebtorStatus.success,
          debtors: _debtors,
          debtorDetail: updated?.debtorId == state.debtorDetail?.debtorId
              ? updated
              : state.debtorDetail,
          isSubmitting: false,
          lastMessageCode: 'DEBTOR_UPDATED',
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DebtorStatus.failure,
          isSubmitting: false,
          errorMessage: _parseErrorMessage(e),
          lastMessageCode: 'DEBTOR_UPDATE_FAILED',
        ),
      );
    }
  }

  Future<void> _onRecordDebtAdjustmentRequested(
    RecordDebtAdjustmentRequested event,
    Emitter<DebtorState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      await repository.recordDebtAdjustment(
        debtorId: event.debtorId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        notes: event.notes,
      );

      final detail = await repository.getDebtorDetail(event.debtorId);
      final history = await repository.getDebtPaymentHistory(event.debtorId);

      if (detail != null) {
        _debtors = _debtors
            .map(
              (debtor) => debtor.debtorId == detail.debtorId ? detail : debtor,
            )
            .toList();
      }

      emit(
        state.copyWith(
          status: DebtorStatus.success,
          debtors: _debtors,
          debtorDetail: detail ?? state.debtorDetail,
          paymentHistory: history,
          isSubmitting: false,
          lastMessageCode: 'DEBT_ADJUSTMENT_RECORDED',
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DebtorStatus.failure,
          isSubmitting: false,
          errorMessage: _parseErrorMessage(e),
          lastMessageCode: 'DEBT_ADJUSTMENT_FAILED',
        ),
      );
    }
  }

  Future<void> _onLoadDebtorDetailRequested(
    LoadDebtorDetailRequested event,
    Emitter<DebtorState> emit,
  ) async {
    try {
      final detail = await repository.getDebtorDetail(event.debtorId);
      if (detail != null) {
        _debtors = _debtors
            .map(
              (debtor) => debtor.debtorId == detail.debtorId ? detail : debtor,
            )
            .toList();
      }
      emit(
        state.copyWith(
          debtors: _debtors,
          debtorDetail: detail,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: _parseErrorMessage(e)));
    }
  }

  Future<void> _onLoadDebtPaymentHistoryRequested(
    LoadDebtPaymentHistoryRequested event,
    Emitter<DebtorState> emit,
  ) async {
    try {
      final history = await repository.getDebtPaymentHistory(event.debtorId);
      emit(state.copyWith(paymentHistory: history, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(errorMessage: _parseErrorMessage(e)));
    }
  }

  Future<void> _onLoadActiveDebtorsByLocation(
    LoadActiveDebtorsByLocationRequested event,
    Emitter<DebtorState> emit,
  ) async {
    final cacheKey =
        'cache_debtors_active_location_${BusinessContext().currentBusinessId ?? 'all'}_${event.locationId}';

    await CacheManager().fetchWithSWR<List<DebtorEntity>>(
      key: cacheKey,
      fetcher: ({cancelToken}) => repository.getActiveDebtorsByLocation(event.locationId),
      fromJson: (json) {
        // BE returns { "data": [...] } — a direct list, not paginated
        // DebtorMinimalDto is missing isActive & businessLocationId,
        // so we inject them after parsing since this endpoint only returns
        // active debtors for a specific location.
        final raw = json['data'];
        List? list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic> && raw['items'] is List) {
          list = raw['items'] as List;
        }
        if (list == null) return <DebtorEntity>[];
        return list
            .whereType<Map<String, dynamic>>()
            .map((m) {
              // Inject missing fields from the minimal DTO
              final patched = Map<String, dynamic>.from(m)
                ..putIfAbsent('isActive', () => true)
                ..putIfAbsent('businessLocationId', () => event.locationId)
                ..putIfAbsent('businessLocationName', () => '');
              return DebtorEntity.fromMap(patched);
            })
            .toList();
      },
      toJson: (data) {
        return {'data': data.map((e) => e.toMap()).toList()};
      },
      onData: (data, _) {
        debugPrint(
          'DebtorBloc._onLoadActiveDebtorsByLocation: loaded ${data.length} debtors for location ${event.locationId}',
        );
        emit(state.copyWith(activeDebtorsByLocation: data, errorMessage: null));
      },
      onError: (error) {
        debugPrint('DebtorBloc._onLoadActiveDebtorsByLocation error: $error');
      },
    );
  }

  List<int>? _resolveBusinessLocationIds({List<int>? explicit}) {
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return null;
  }

  String _parseErrorMessage(dynamic error) {
    if (error is Exception) {
      final text = error.toString();
      return text.replaceFirst('Exception: ', '');
    }
    return error?.toString() ?? 'Unknown error';
  }

  void _onResetDebtors(ResetDebtors event, Emitter<DebtorState> emit) {
    _debtors = [];
    emit(const DebtorState());
  }
}
