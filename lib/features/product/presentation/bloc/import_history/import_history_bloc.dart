import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/import_repository.dart';
import '../../../data/models/import_model.dart';
import '../../../../../shared/context/business_context.dart';
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

  int? get _currentBusinessLocationId {
    final id = BusinessContext().currentBusinessId;
    if (id == null) return null;
    return int.tryParse(id);
  }

  Future<void> _onLoadImportHistory(
    LoadImportHistory event,
    Emitter<ImportHistoryState> emit,
  ) async {
    emit(state.copyWith(status: ImportHistoryStatus.loading));

    final effectiveLocationId = state.businessLocationId ?? _currentBusinessLocationId;

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

      final itemsRaw = response['items'] as List;
      final items = itemsRaw
          .map((e) => ImportHistoryItemModel.fromJson(e))
          .toList();

      emit(
        state.copyWith(
          status: ImportHistoryStatus.success,
          items: items,
          hasReachedMax: response['hasNextPage'] == false,
          currentPage: 1,
        ),
      );
    } catch (e) {
      debugPrint('ImportHistoryBloc load error: $e');
      emit(
        state.copyWith(
          status: ImportHistoryStatus.failure,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
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

      final itemsRaw = response['items'] as List;
      final items = itemsRaw
          .map((e) => ImportHistoryItemModel.fromJson(e))
          .toList();

      emit(
        state.copyWith(
          status: ImportHistoryStatus.success,
          items: List.of(state.items)..addAll(items),
          hasReachedMax: response['hasNextPage'] == false,
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
