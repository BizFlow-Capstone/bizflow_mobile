import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/cost_repository.dart';
import '../../domain/entities/cost_entity.dart';
import 'cost_event.dart';
import 'cost_state.dart';

export 'cost_event.dart';
export 'cost_state.dart';

class CostBloc extends Bloc<CostEvent, CostState> {
  final CostRepository repository;

  CostBloc({required this.repository}) : super(const CostInitial()) {
    on<LoadCostsRequested>(_onLoadCostsRequested);
    on<CreateManualCostRequested>(_onCreateManualCostRequested);
    on<UpdateManualCostRequested>(_onUpdateManualCostRequested);
    on<DeleteManualCostRequested>(_onDeleteManualCostRequested);
    on<ResetCosts>(_onResetCosts);
  }

  void _onResetCosts(ResetCosts event, Emitter<CostState> emit) {
    emit(const CostInitial());
  }

  Future<void> _onLoadCostsRequested(
    LoadCostsRequested event,
    Emitter<CostState> emit,
  ) async {
    final currentState = state;

    if (!event.isLoadMore) {
      emit(const CostsLoading());
    }

    if (event.isLoadMore && currentState is CostsLoaded) {
      emit(CostsLoaded(
        costs: currentState.costs,
        allCosts: currentState.allCosts,
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

      await repository.getCostsSWR(
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        businessLocationId: locationIdInt,
        fromDate: event.fromDate,
        toDate: event.toDate,
        onData: (costs, totalCount, isFromCache) {
          hasDeliveredData = true;
          // Append if load more
          List<CostEntity> master = costs;
          if (event.isLoadMore && currentState is CostsLoaded) {
            master = List.of(currentState.allCosts)..addAll(costs);
            final ids = <int>{};
            master.retainWhere((x) => ids.add(x.id));
          }

          final hasReachedMax = master.length >= totalCount || costs.length < event.pageSize;

          emit(
            CostsLoaded(
              costs: master,
              allCosts: master,
              totalCount: totalCount,
              pageNumber: event.pageNumber,
              pageSize: event.pageSize,
              isFromCache: isFromCache,
              isLoadMore: false,
              hasReachedMax: hasReachedMax,
            ),
          );
        },
        onError: (error) {
          if (!hasDeliveredData) {
            emit(CostError(error.toString()));
          }
        },
      );
    } catch (e) {
      if (!hasDeliveredData) {
        emit(CostError(e.toString()));
      }
    }
  }

  Future<void> _onCreateManualCostRequested(
    CreateManualCostRequested event,
    Emitter<CostState> emit,
  ) async {
    try {
      await repository.createManualCost(event.body, image: event.image);
      emit(const CostOperationSuccess('cost_created_successfully'));
    } catch (e) {
      emit(CostOperationFailure(e.toString()));
    }
  }

  Future<void> _onUpdateManualCostRequested(
    UpdateManualCostRequested event,
    Emitter<CostState> emit,
  ) async {
    try {
      await repository.updateManualCost(
        event.costId,
        event.body,
        image: event.image,
        idempotencyKey: event.idempotencyKey,
      );
      emit(const CostOperationSuccess('cost_updated_successfully'));
    } catch (e) {
      emit(CostOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteManualCostRequested(
    DeleteManualCostRequested event,
    Emitter<CostState> emit,
  ) async {
    try {
      await repository.deleteManualCost(event.costId);
      emit(const CostOperationSuccess('cost_deleted_successfully'));
    } catch (e) {
      emit(CostOperationFailure(e.toString()));
    }
  }
}
