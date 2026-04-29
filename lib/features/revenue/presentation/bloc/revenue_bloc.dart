import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message_parser.dart';
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
    emit(const RevenuesLoading());
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
          hasDeliveredData = true;
          if (!emit.isDone) {
            emit(
              RevenuesLoaded(
                revenues: revenues,
                totalCount: totalCount,
                pageNumber: event.pageNumber,
                pageSize: event.pageSize,
                isFromCache: isFromCache,
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
