import 'package:equatable/equatable.dart';
import '../../domain/entities/cost_entity.dart';

abstract class CostState extends Equatable {
  const CostState();

  @override
  List<Object?> get props => [];
}

class CostInitial extends CostState {
  const CostInitial();
}

class CostsLoading extends CostState {
  const CostsLoading();
}

class CostsLoaded extends CostState {
  final List<CostEntity> costs;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final bool isFromCache;

  const CostsLoaded({
    required this.costs,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [costs, totalCount, pageNumber, pageSize, isFromCache];
}

class CostError extends CostState {
  final String message;

  const CostError(this.message);

  @override
  List<Object?> get props => [message];
}

class CostOperationSuccess extends CostState {
  final String message;

  const CostOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CostOperationFailure extends CostState {
  final String message;

  const CostOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
