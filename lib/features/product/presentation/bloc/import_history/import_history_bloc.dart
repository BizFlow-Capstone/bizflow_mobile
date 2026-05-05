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
    on<SearchImportHistory>(_onSearchImportHistory);
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

    final effectiveLocationId =
        state.businessLocationId ?? _currentBusinessLocationId;

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

      final filtered = _applyLocalFilters(items, state.searchQuery);

      emit(
        state.copyWith(
          status: ImportHistoryStatus.success,
          items: filtered,
          allItems: items,
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
    if (state.hasReachedMax ||
        state.status == ImportHistoryStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: ImportHistoryStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getImports(
        status: state.statusFilter,
        importType: state.typeFilter,
        businessLocationId:
            state.businessLocationId ?? _currentBusinessLocationId,
        fromDate: state.fromDate,
        toDate: state.toDate,
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      final itemsRaw = response['items'] as List;
      final items = itemsRaw
          .map((e) => ImportHistoryItemModel.fromJson(e))
          .toList();

      final newMasterList = List.of(state.allItems)..addAll(items);
      final filtered = _applyLocalFilters(newMasterList, state.searchQuery);

      emit(
        state.copyWith(
          status: ImportHistoryStatus.success,
          items: filtered,
          allItems: newMasterList,
          hasReachedMax: response['hasNextPage'] == false,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportHistoryStatus.failure,
          errorMessage: ApiErrorMessageParser.parse(e),
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
    // If location or date range changed, we must reload from API
    if (event.businessLocationId != state.businessLocationId ||
        event.fromDate != state.fromDate ||
        event.toDate != state.toDate) {
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
    } else {
      // Otherwise we can probably filter locally if we have the master list
      // Note: In this specific bloc, filters were passed to API.
      // If we want local filtering, we need to apply them to allItems.
      // However, usually "status" and "type" are small enough sets that local filtering is preferred.
      
      final newState = state.copyWith(
        statusFilter: event.statusFilter,
        typeFilter: event.typeFilter,
      );
      
      final filtered = _applyLocalFilters(newState.allItems, newState.searchQuery, 
          status: event.statusFilter, type: event.typeFilter);
      
      emit(newState.copyWith(items: filtered));
    }
  }

  void _onSearchImportHistory(
    SearchImportHistory event,
    Emitter<ImportHistoryState> emit,
  ) {
    final filtered = _applyLocalFilters(state.allItems, event.keyword,
        status: state.statusFilter, type: state.typeFilter);
    emit(state.copyWith(items: filtered, searchQuery: event.keyword));
  }

  List<ImportHistoryItemModel> _applyLocalFilters(
    List<ImportHistoryItemModel> items,
    String? search, {
    String? status,
    String? type,
  }) {
    var result = List<ImportHistoryItemModel>.from(items);

    // 1. Status Filter (Local)
    if (status != null && status.isNotEmpty && status != 'ALL') {
      result = result.where((item) => item.status.toUpperCase() == status.toUpperCase()).toList();
    }

    // 2. Type Filter (Local)
    if (type != null && type.isNotEmpty && type != 'ALL') {
      result = result.where((item) => item.importType.toUpperCase() == type.toUpperCase()).toList();
    }

    // 3. Search Keyword
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      result = result.where((item) {
        final code = item.importCode.toLowerCase();
        final note = (item.note ?? '').toLowerCase();
        final supplier = (item.supplier ?? '').toLowerCase();
        final id = item.importId.toString();
        
        return code.contains(query) || 
               note.contains(query) || 
               supplier.contains(query) || 
               id.contains(query);
      }).toList();
    }

    return result;
  }
}
