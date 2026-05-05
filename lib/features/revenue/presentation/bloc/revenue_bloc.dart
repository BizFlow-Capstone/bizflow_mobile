import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../data/revenue_repository.dart';
import '../../domain/entities/revenue_entity.dart';
import 'revenue_event.dart';
import 'revenue_state.dart';

export 'revenue_event.dart';
export 'revenue_state.dart';

class RevenueBloc extends Bloc<RevenueEvent, RevenueState> {
  final RevenueRepository repository;

  RevenueBloc({required this.repository}) : super(const RevenueInitial()) {
    on<LoadRevenuesRequested>(_onLoadRevenuesRequested);
    on<CreateManualRevenueRequested>(_onCreateManualRevenueRequested);
    on<UpdateManualRevenueRequested>(_onUpdateManualRevenueRequested);
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
    final currentState = state;

    // Only emit standard loading when not paginating
    if (!event.isLoadMore) {
      emit(const RevenuesLoading());
    }

    // If this is a load-more request, mark current state as loading more
    if (event.isLoadMore && currentState is RevenuesLoaded) {
      emit(RevenuesLoaded(
        revenues: currentState.revenues,
        allRevenues: currentState.allRevenues,
        totalCount: currentState.totalCount,
        pageNumber: currentState.pageNumber,
        pageSize: currentState.pageSize,
        isFromCache: currentState.isFromCache,
        isLoadMore: true,
        hasReachedMax: currentState.hasReachedMax,
      ));
    }

    var hasDeliveredData = false;
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
          // Append if load more
          List<RevenueEntity> master = revenues;
          if (event.isLoadMore && currentState is RevenuesLoaded) {
            master = List.of(currentState.allRevenues)..addAll(revenues);
            final ids = <int>{};
            master.retainWhere((x) => ids.add(x.id));
          }

          final hasReachedMax = master.length >= totalCount || revenues.length < event.pageSize;

          if (!emit.isDone) {
            emit(
              RevenuesLoaded(
                revenues: master,
                allRevenues: master,
                totalCount: totalCount,
                pageNumber: event.pageNumber,
                pageSize: event.pageSize,
                isFromCache: isFromCache,
                isLoadMore: false,
                hasReachedMax: hasReachedMax,
              ),
            );
          }
        },
        onError: (error) {
          if (!emit.isDone && !hasDeliveredData) {
            emit(RevenueError(message: ApiErrorMessageParser.parse(error)));
          }
        },
      );
    } catch (e) {
      emit(RevenueError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onCreateManualRevenueRequested(
    CreateManualRevenueRequested event,
    Emitter<RevenueState> emit,
  ) async {
    try {
      final revenue = await repository.createManualRevenue(
        event.body,
        image: event.image,
      );
      emit(RevenueCreated(revenue: revenue));

      if (event.body['businessLocationId'] != null) {
        add(
          LoadRevenuesRequested(
            businessLocationId: event.body['businessLocationId'].toString(),
          ),
        );
      }
    } catch (e) {
      emit(RevenueError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onDeleteManualRevenueRequested(
    DeleteManualRevenueRequested event,
    Emitter<RevenueState> emit,
  ) async {
    try {
      await repository.deleteManualRevenue(event.revenueId);
      emit(RevenueDeleted(revenueId: event.revenueId));
      add(LoadRevenuesRequested(businessLocationId: event.businessLocationId));
    } catch (e) {
      emit(RevenueError(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onUpdateManualRevenueRequested(
    UpdateManualRevenueRequested event,
    Emitter<RevenueState> emit,
  ) async {
    try {
      final revenue = await repository.updateManualRevenue(
        event.revenueId,
        event.body,
        image: event.image,
        idempotencyKey: event.idempotencyKey,
      );
      emit(RevenueUpdated(revenue: revenue));

      final locationId = event.body['businessLocationId']?.toString();
      add(LoadRevenuesRequested(businessLocationId: locationId));
    } catch (e) {
      emit(RevenueError(message: ApiErrorMessageParser.parse(e)));
    }
  }
}
