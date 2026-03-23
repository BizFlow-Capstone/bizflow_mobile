import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/revenue_repository.dart';
import 'revenue_event.dart';
import 'revenue_state.dart';

export 'revenue_event.dart';
export 'revenue_state.dart';

class RevenueBloc extends Bloc<RevenueEvent, RevenueState> {
  final RevenueRepository repository;

  RevenueBloc({required this.repository}) : super(const RevenueInitial()) {
    on<LoadRevenuesRequested>(_onLoadRevenuesRequested);
    on<CreateManualRevenueRequested>(_onCreateManualRevenueRequested);
    on<DeleteManualRevenueRequested>(_onDeleteManualRevenueRequested);
    on<ResetRevenues>(_onResetRevenues);
  }

  void _onResetRevenues(ResetRevenues event, Emitter<RevenueState> emit) {
    emit(const RevenueInitial());
  }

  Future<void> _onLoadRevenuesRequested(
    LoadRevenuesRequested event,
    Emitter<RevenueState> emit,
  ) async {
    emit(const RevenuesLoading());
    try {
      final locationIdInt = event.businessLocationId != null
          ? int.tryParse(event.businessLocationId!)
          : null;

      await repository.getRevenuesSWR(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        businessLocationId: locationIdInt,
        fromDate: event.fromDate,
        toDate: event.toDate,
        onData: (revenues, totalCount, isFromCache) {
          emit(
            RevenuesLoaded(
              revenues: revenues,
              totalCount: totalCount,
              pageNumber: event.pageNumber,
              pageSize: event.pageSize,
              isFromCache: isFromCache,
            ),
          );
        },
        onError: (error) {
          emit(RevenueError(message: error.toString()));
        },
      );
    } catch (e) {
      emit(RevenueError(message: e.toString()));
    }
  }

  Future<void> _onCreateManualRevenueRequested(
    CreateManualRevenueRequested event,
    Emitter<RevenueState> emit,
  ) async {
    try {
      final revenue = await repository.createManualRevenue(event.body);
      emit(RevenueCreated(revenue: revenue));
      
      // Optionally reload list
      // add(LoadRevenuesRequested(businessLocationId: event.body['businessLocationId']));
    } catch (e) {
      emit(RevenueError(message: e.toString()));
    }
  }

  Future<void> _onDeleteManualRevenueRequested(
    DeleteManualRevenueRequested event,
    Emitter<RevenueState> emit,
  ) async {
    try {
      await repository.deleteManualRevenue(event.revenueId);
      emit(RevenueDeleted(revenueId: event.revenueId));
    } catch (e) {
      emit(RevenueError(message: e.toString()));
    }
  }
}
