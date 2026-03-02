import 'package:equatable/equatable.dart';
import '../../../data/models/import_model.dart';

enum ImportHistoryStatus { initial, loading, loadingMore, success, failure }

class ImportHistoryState extends Equatable {
  final ImportHistoryStatus status;
  final List<ImportHistoryItemModel> items;
  final bool hasReachedMax;
  final int currentPage;
  final String? errorMessage;

  // Filters
  final String? statusFilter;
  final String? typeFilter;
  final int? businessLocationId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ImportHistoryState({
    this.status = ImportHistoryStatus.initial,
    this.items = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.errorMessage,
    this.statusFilter,
    this.typeFilter,
    this.businessLocationId,
    this.fromDate,
    this.toDate,
  });

  ImportHistoryState copyWith({
    ImportHistoryStatus? status,
    List<ImportHistoryItemModel>? items,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
    String? statusFilter,
    String? typeFilter,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ImportHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    hasReachedMax,
    currentPage,
    errorMessage,
    statusFilter,
    typeFilter,
    businessLocationId,
    fromDate,
    toDate,
  ];
}
