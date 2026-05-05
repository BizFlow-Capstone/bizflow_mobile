import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CostEvent extends Equatable {
  const CostEvent();

  @override
  List<Object?> get props => [];
}

class LoadCostsRequested extends CostEvent {
  final int pageNumber;
  final int pageSize;
  final String? businessLocationId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isLoadMore;

  const LoadCostsRequested({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.businessLocationId,
    this.fromDate,
    this.toDate,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, businessLocationId, fromDate, toDate, isLoadMore];
}

class CreateManualCostRequested extends CostEvent {
  final Map<String, dynamic> body;
  final File? image;

  const CreateManualCostRequested({required this.body, this.image});

  @override
  List<Object?> get props => [body, image];
}

class UpdateManualCostRequested extends CostEvent {
  final int costId;
  final Map<String, dynamic> body;
  final File? image;
  final String? idempotencyKey;

  const UpdateManualCostRequested({
    required this.costId,
    required this.body,
    this.image,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [costId, body, image, idempotencyKey];
}

class DeleteManualCostRequested extends CostEvent {
  final int costId;

  const DeleteManualCostRequested(this.costId);

  @override
  List<Object?> get props => [costId];
}

class ResetCosts extends CostEvent {
  const ResetCosts();
}
