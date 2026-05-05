import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/network/api_error_message_parser.dart';
import '../../../data/repositories/gl_repository.dart';
import '../../../data/models/general_ledger_entry_model.dart';
import 'gl_event.dart';
import 'gl_state.dart';

class GLBloc extends Bloc<GLEvent, GLState> {
  final GLRepository repository;

  GLBloc({required this.repository}) : super(GLInitial()) {
    on<LoadGLEntriesRequested>(_onLoadGLEntriesRequested);
    on<ChangeGLFiltersRequested>(_onChangeGLFiltersRequested);
    on<SearchGLEntriesRequested>(_onSearchGLEntriesRequested);
  }

  Future<void> _onLoadGLEntriesRequested(
    LoadGLEntriesRequested event,
    Emitter<GLState> emit,
  ) async {
    final currentState = state;
    
    // Only emit standard loading if not paginating
    if (!event.isLoadMore) {
      emit(GLLoading());
    }

    // If this is a load-more request, mark current state as loading more
    if (event.isLoadMore && currentState is GLLoaded) {
      emit(currentState.copyWith(isLoadMore: true));
    }

    try {
      await repository.fetchGLEntriesSWR(
        businessLocationId: event.businessLocationId,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        transactionTypes: event.transactionTypes,
        referenceTypes: event.referenceTypes,
        moneyChannels: event.moneyChannels,
        fromDate: event.fromDate,
        toDate: event.toDate,
        viewMode: event.viewMode,
        onData: (data, totalCount, isFromCache) {
          // Append if load more
          List<GeneralLedgerEntryModel> masterEntries = data;
          if (event.isLoadMore && currentState is GLLoaded) {
            masterEntries = List.of(currentState.allEntries)..addAll(data);
            // Deduplicate based on ID if needed
            final ids = <int>{};
            masterEntries.retainWhere((x) => ids.add(x.entryId));
          }
          
          final hasReachedMax = masterEntries.length >= totalCount || data.length < event.pageSize;

          final searchKeyword = (currentState is GLLoaded) ? currentState.searchQuery : null;
          final filtered = _applyLocalFilters(masterEntries, searchKeyword);

          emit(GLLoaded(
            entries: filtered,
            allEntries: masterEntries,
            totalCount: totalCount,
            isFromCache: isFromCache,
            // loading has finished, reset load-more flag
            isLoadMore: false,
            pageNumber: event.pageNumber,
            pageSize: event.pageSize,
            hasReachedMax: hasReachedMax,
            businessLocationId: event.businessLocationId,
            searchQuery: searchKeyword,
            transactionTypes: event.transactionTypes ?? [],
            referenceTypes: event.referenceTypes ?? [],
            moneyChannels: event.moneyChannels ?? [],
            fromDate: event.fromDate,
            toDate: event.toDate,
            viewMode: event.viewMode,
          ));
        },
        onError: (e) {
          if (!isClosed) {
            final prevEntries = currentState is GLLoaded ? currentState.entries : null;
            emit(GLError(ApiErrorMessageParser.parse(e), previousEntries: prevEntries));
          }
        },
      );
    } catch (error) {
      final prevEntries = currentState is GLLoaded ? currentState.entries : null;
      emit(GLError(ApiErrorMessageParser.parse(error), previousEntries: prevEntries));
    }
  }

  Future<void> _onChangeGLFiltersRequested(
    ChangeGLFiltersRequested event,
    Emitter<GLState> emit,
  ) async {
    final currentState = state;
    if (currentState is GLLoaded) {
      // If we only changed viewMode, we can potentially filter locally too? 
      // But typically viewMode (audit/standard) might require different data fields from API.
      // So we keep standard full reload for viewMode change.
      
      // Reset pagination and reload
      add(LoadGLEntriesRequested(
        businessLocationId: currentState.businessLocationId,
        pageNumber: 1,
        pageSize: currentState.pageSize,
        transactionTypes: event.transactionTypes,
        referenceTypes: event.referenceTypes,
        moneyChannels: event.moneyChannels,
        fromDate: event.fromDate,
        toDate: event.toDate,
        viewMode: event.viewMode ?? currentState.viewMode,
      ));
    }
  }

  void _onSearchGLEntriesRequested(
    SearchGLEntriesRequested event,
    Emitter<GLState> emit,
  ) {
    final s = state;
    if (s is GLLoaded) {
      final filtered = _applyLocalFilters(s.allEntries, event.keyword);
      emit(s.copyWith(entries: filtered, searchQuery: event.keyword));
    }
  }

  List<GeneralLedgerEntryModel> _applyLocalFilters(
    List<GeneralLedgerEntryModel> entries,
    String? search,
  ) {
    if (search == null || search.trim().isEmpty) {
      return List.from(entries);
    }

    final query = search.trim().toLowerCase();
    return entries.where((e) {
      final note = e.note.toLowerCase();
      final docNum = e.documentNumber.toLowerCase();
      final amount = e.amount.toString();
      final channel = (e.moneyChannel ?? '').toLowerCase();
      final type = e.transactionType.toLowerCase();
      
      return note.contains(query) ||
             docNum.contains(query) ||
             amount.contains(query) ||
             channel.contains(query) ||
             type.contains(query);
    }).toList();
  }
}
