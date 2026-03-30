import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/import_repository.dart';
import '../../../data/models/import_model.dart';
import '../../../../../shared/cache/cache_manager.dart';
import '../../../../../shared/context/business_context.dart';
import '../../../../../shared/utils/date_formatter.dart';
import 'import_history_event.dart';
import 'import_history_state.dart';
import '../../../../../core/network/api_error_message_parser.dart';

class ImportHistoryBloc extends Bloc<ImportHistoryEvent, ImportHistoryState> {
  final ImportRepository _repository;

  static const int _pageSize = 10;

  ImportHistoryBloc({required ImportRepository repository})
    : _repository = repository,
      super(const ImportHistoryState()) {
    on<LoadImportHistory>(_onLoadImportHistory);
    on<LoadMoreImportHistory>(_onLoadMoreImportHistory);
    on<RefreshImportHistory>(_onRefreshImportHistory);
    on<UpdateFilters>(_onUpdateFilters);
  }

  /// Kiểm tra có filter nào đang active không
  bool get _hasActiveFilters =>
      state.statusFilter != null ||
      state.typeFilter != null ||
      state.businessLocationId != null ||
      state.fromDate != null ||
      state.toDate != null;

  int? get _currentBusinessLocationId {
    final id = BusinessContext().currentBusinessId;
    if (id == null) return null;
    return int.tryParse(id);
  }

  String _cacheKey({required int? locationId}) {
    final businessId = BusinessContext().currentBusinessId ?? 'all';
    final status = state.statusFilter ?? 'all';
    final type = state.typeFilter ?? 'all';
    final from = state.fromDate != null
        ? DateFormatter.toApiUtcIsoString(state.fromDate!)
        : 'none';
    final to = state.toDate != null
        ? DateFormatter.toApiUtcIsoString(state.toDate!)
        : 'none';
    final location = locationId?.toString() ?? 'all';
    return 'cache_import_history_${businessId}_${location}_${status}_${type}_${from}_${to}';
  }

  Future<void> _onLoadImportHistory(
    LoadImportHistory event,
    Emitter<ImportHistoryState> emit,
  ) async {
    emit(state.copyWith(status: ImportHistoryStatus.loading));

    final effectiveLocationId = state.businessLocationId ?? _currentBusinessLocationId;
    final cacheKey = _cacheKey(locationId: effectiveLocationId);

    // Chỉ dùng SWR cache cho trang đầu tiên khi không có filter
    if (!_hasActiveFilters) {
      await CacheManager().fetchWithSWR<List<ImportHistoryItemModel>>(
        key: cacheKey,
        fetcher: ({cancelToken}) async {
          final response = await _repository.getImports(
            businessLocationId: effectiveLocationId,
            pageNumber: 1,
            pageSize: _pageSize,
          );
          final itemsRaw = response['data']['items'] as List;
          return itemsRaw
              .map((e) => ImportHistoryItemModel.fromJson(e))
              .toList();
        },
        fromJson: (json) {
          final list = json['data'] as List;
          return list
              .map(
                (e) =>
                    ImportHistoryItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        },
        toJson: (data) {
          return {'data': data.map((e) => e.toJson()).toList()};
        },
        onData: (items, isFromCache) {
          emit(
            state.copyWith(
              status: ImportHistoryStatus.success,
              items: items,
              hasReachedMax: items.length < _pageSize,
              currentPage: 1,
            ),
          );
        },
        onError: (e) {
          debugPrint('ImportHistoryBloc SWR error: $e');
          emit(
            state.copyWith(
              status: ImportHistoryStatus.failure,
              errorMessage: ApiErrorMessageParser.parse(e),
            ),
          );
        },
      );
    } else {
      // Có filter → gọi API trực tiếp, không cache
      try {
        final response = await _repository.getImports(
          status: state.statusFilter,
          importType: state.typeFilter,
          businessLocationId: effectiveLocationId,
          fromDate: state.fromDate,
          toDate: state.toDate,
          pageNumber: 1,
          pageSize: _pageSize,
        );

        final itemsRaw = response['data']['items'] as List;
        final items = itemsRaw
            .map((e) => ImportHistoryItemModel.fromJson(e))
            .toList();

        emit(
          state.copyWith(
            status: ImportHistoryStatus.success,
            items: items,
            hasReachedMax: response['data']['hasNextPage'] == false,
            currentPage: 1,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: ImportHistoryStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onLoadMoreImportHistory(
    LoadMoreImportHistory event,
    Emitter<ImportHistoryState> emit,
  ) async {
    if (state.hasReachedMax || state.status == ImportHistoryStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: ImportHistoryStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getImports(
        status: state.statusFilter,
        importType: state.typeFilter,
        businessLocationId: state.businessLocationId ?? _currentBusinessLocationId,
        fromDate: state.fromDate,
        toDate: state.toDate,
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      final itemsRaw = response['data']['items'] as List;
      final items = itemsRaw
          .map((e) => ImportHistoryItemModel.fromJson(e))
          .toList();

      emit(
        state.copyWith(
          status: ImportHistoryStatus.success,
          items: List.of(state.items)..addAll(items),
          hasReachedMax: response['data']['hasNextPage'] == false,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportHistoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshImportHistory(
    RefreshImportHistory event,
    Emitter<ImportHistoryState> emit,
  ) async {
    add(const LoadImportHistory());
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<ImportHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        statusFilter: event.statusFilter,
        typeFilter: event.typeFilter,
        businessLocationId: event.businessLocationId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      ),
    );
    add(const LoadImportHistory());
  }
}
