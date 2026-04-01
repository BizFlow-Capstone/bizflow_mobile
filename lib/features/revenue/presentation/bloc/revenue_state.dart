import 'package:equatable/equatable.dart';
import '../../domain/entities/revenue_entity.dart';

abstract class RevenueState extends Equatable {
  const RevenueState();

  @override
  List<Object?> get props => [];
}

class RevenueInitial extends RevenueState {
  const RevenueInitial();
}

class RevenuesLoading extends RevenueState {
  const RevenuesLoading();
}

class RevenuesLoaded extends RevenueState {
  final List<RevenueEntity> revenues;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final bool isFromCache;

  const RevenuesLoaded({
    required this.revenues,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [revenues, totalCount, pageNumber, pageSize, isFromCache];
}

class RevenueCreated extends RevenueState {
  final RevenueEntity revenue;

  const RevenueCreated({required this.revenue});

  @override
  List<Object?> get props => [revenue];
}

class RevenueUpdated extends RevenueState {
  final RevenueEntity revenue;

  const RevenueUpdated({required this.revenue});

  @override
  List<Object?> get props => [revenue];
}

class RevenueDeleted extends RevenueState {
  final int revenueId;

  const RevenueDeleted({required this.revenueId});

  @override
  List<Object?> get props => [revenueId];
}

class RevenueError extends RevenueState {
  final String message;

  const RevenueError({required this.message});

  @override
  List<Object?> get props => [message];
}
