import 'package:equatable/equatable.dart';
import 'dart:io';

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
  final bool isLoadMore;

  const LoadRevenuesRequested({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.businessLocationId,
    this.fromDate,
    this.toDate,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [
    pageNumber,
    pageSize,
    businessLocationId,
    fromDate,
    toDate,
    isLoadMore,
  ];
}

class CreateManualRevenueRequested extends RevenueEvent {
  final Map<String, dynamic> body;
  final File? image;

  const CreateManualRevenueRequested({required this.body, this.image});

  @override
  List<Object?> get props => [body, image];
}

class UpdateManualRevenueRequested extends RevenueEvent {
  final int revenueId;
  final Map<String, dynamic> body;
  final File? image;
  final String? idempotencyKey;

  const UpdateManualRevenueRequested({
    required this.revenueId,
    required this.body,
    this.image,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [revenueId, body, image, idempotencyKey];
}

class DeleteManualRevenueRequested extends RevenueEvent {
  final int revenueId;
  final String? businessLocationId;

  const DeleteManualRevenueRequested({
    required this.revenueId,
    this.businessLocationId,
  });

  @override
  List<Object?> get props => [revenueId, businessLocationId];
}

class ResetRevenues extends RevenueEvent {
  const ResetRevenues();
}
