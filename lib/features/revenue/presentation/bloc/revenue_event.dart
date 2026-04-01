import 'package:equatable/equatable.dart';

abstract class RevenueEvent extends Equatable {
  const RevenueEvent();

  @override
  List<Object?> get props => [];
}

class LoadRevenuesRequested extends RevenueEvent {
  final int pageNumber;
  final int pageSize;
  final String? businessLocationId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadRevenuesRequested({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.businessLocationId,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, businessLocationId, fromDate, toDate];
}

class CreateManualRevenueRequested extends RevenueEvent {
  final Map<String, dynamic> body;

  const CreateManualRevenueRequested({required this.body});

  @override
  List<Object?> get props => [body];
}

class UpdateManualRevenueRequested extends RevenueEvent {
  final int revenueId;
  final Map<String, dynamic> body;

  const UpdateManualRevenueRequested({
    required this.revenueId,
    required this.body,
  });

  @override
  List<Object?> get props => [revenueId, body];
}

class DeleteManualRevenueRequested extends RevenueEvent {
  final int revenueId;

  const DeleteManualRevenueRequested({required this.revenueId});

  @override
  List<Object?> get props => [revenueId];
}

class ResetRevenues extends RevenueEvent {
  const ResetRevenues();
}
