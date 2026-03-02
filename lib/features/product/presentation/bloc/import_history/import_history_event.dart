import 'package:equatable/equatable.dart';

abstract class ImportHistoryEvent extends Equatable {
  const ImportHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadImportHistory extends ImportHistoryEvent {
  const LoadImportHistory();
}

class LoadMoreImportHistory extends ImportHistoryEvent {
  const LoadMoreImportHistory();
}

class RefreshImportHistory extends ImportHistoryEvent {
  const RefreshImportHistory();
}

class UpdateFilters extends ImportHistoryEvent {
  final String? statusFilter;
  final String? typeFilter;
  final int? businessLocationId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const UpdateFilters({
    this.statusFilter,
    this.typeFilter,
    this.businessLocationId,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [
    statusFilter,
    typeFilter,
    businessLocationId,
    fromDate,
    toDate,
  ];
}
