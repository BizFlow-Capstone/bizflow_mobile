import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/gl_repository.dart';
import '../../../data/models/general_ledger_entry_model.dart';
import 'gl_event.dart';
import 'gl_state.dart';

class GLBloc extends Bloc<GLEvent, GLState> {
  final GLRepository repository;

  GLBloc({required this.repository}) : super(GLInitial()) {
    on<LoadGLEntriesRequested>(_onLoadGLEntriesRequested);
    on<ChangeGLFiltersRequested>(_onChangeGLFiltersRequested);
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
          if (!isClosed) {
            // Append if load more
            List<GeneralLedgerEntryModel> allEntries = data;
            if (event.isLoadMore && currentState is GLLoaded) {
              allEntries = List.of(currentState.entries)..addAll(data);
              // Deduplicate based on ID if needed, but pagination usually handles this
              final ids = <int>{};
              allEntries.retainWhere((x) => ids.add(x.entryId));
            }
            
            final hasReachedMax = allEntries.length >= totalCount || data.length < event.pageSize;

            emit(GLLoaded(
              entries: allEntries,
              totalCount: totalCount,
              isFromCache: isFromCache,
              isLoadMore: event.isLoadMore,
              pageNumber: event.pageNumber,
              pageSize: event.pageSize,
              hasReachedMax: hasReachedMax,
              transactionTypes: event.transactionTypes ?? [],
              referenceTypes: event.referenceTypes ?? [],
              moneyChannels: event.moneyChannels ?? [],
              fromDate: event.fromDate,
              toDate: event.toDate,
              viewMode: event.viewMode,
            ));
          }
        },
        onError: (e) {
          if (!isClosed) {
            final prevEntries = currentState is GLLoaded ? currentState.entries : null;
            emit(GLError(e.toString(), previousEntries: prevEntries));
          }
        },
      );
    } catch (error) {
       final prevEntries = currentState is GLLoaded ? currentState.entries : null;
       emit(GLError(error.toString(), previousEntries: prevEntries));
    }
  }

  Future<void> _onChangeGLFiltersRequested(
    ChangeGLFiltersRequested event,
    Emitter<GLState> emit,
  ) async {
    final currentState = state;
    if (currentState is GLLoaded) {
      // Just emit a new state with updated filters!
      // The UI will dispatch LoadGLEntriesRequested immediately after.
      emit(currentState.copyWith(
        transactionTypes: event.transactionTypes,
        referenceTypes: event.referenceTypes,
        moneyChannels: event.moneyChannels,
        fromDate: event.fromDate,
        toDate: event.toDate,
        viewMode: event.viewMode,
        // Reset pagination when filters change
        pageNumber: 1,
        entries: [],
        hasReachedMax: false,
      ));
    }
  }
}
