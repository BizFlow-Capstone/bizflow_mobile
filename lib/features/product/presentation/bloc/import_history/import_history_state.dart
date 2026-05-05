import 'package:equatable/equatable.dart';
import '../../../data/models/import_model.dart';

enum ImportHistoryStatus { initial, loading, loadingMore, success, failure }

class ImportHistoryState extends Equatable {
  final ImportHistoryStatus status;
  final List<ImportHistoryItemModel> items; // Filtered list for UI
  final List<ImportHistoryItemModel> allItems; // Master set for local filtering
  final bool hasReachedMax;
  final int currentPage;
  final String? errorMessage;
  final String? searchQuery;

  // Filters
  final String? statusFilter;
  final String? typeFilter;
  final int? businessLocationId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ImportHistoryState({
    this.status = ImportHistoryStatus.initial,
    this.items = const [],
    this.allItems = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.errorMessage,
    this.searchQuery,
    this.statusFilter,
    this.typeFilter,
    this.businessLocationId,
    this.fromDate,
    this.toDate,
  });

  ImportHistoryState copyWith({
    ImportHistoryStatus? status,
    List<ImportHistoryItemModel>? items,
    List<ImportHistoryItemModel>? allItems,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
    String? searchQuery,
    String? statusFilter,
    String? typeFilter,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ImportHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      allItems: allItems ?? this.allItems,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
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
    allItems,
    hasReachedMax,
    currentPage,
    errorMessage,
    searchQuery,
    statusFilter,
    typeFilter,
    businessLocationId,
    fromDate,
    toDate,
  ];
}
