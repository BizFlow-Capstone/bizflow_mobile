import 'package:equatable/equatable.dart';
import '../../../data/models/general_ledger_entry_model.dart';

abstract class GLState extends Equatable {
  const GLState();

  @override
  List<Object?> get props => [];
}

class GLInitial extends GLState {}

class GLLoading extends GLState {}

class GLLoaded extends GLState {
  final List<GeneralLedgerEntryModel> entries;
  final int totalCount;
  final bool isFromCache;
  final bool isLoadMore;
  final int pageNumber;
  final int pageSize;
  final bool hasReachedMax;

  // Filters state
  final List<String> transactionTypes;
  final List<String> referenceTypes;
  final List<String> moneyChannels;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String viewMode;

  const GLLoaded({
    required this.entries,
    required this.totalCount,
    this.isFromCache = false,
    this.isLoadMore = false,
    required this.pageNumber,
    required this.pageSize,
    required this.hasReachedMax,
    this.transactionTypes = const [],
    this.referenceTypes = const [],
    this.moneyChannels = const [],
    this.fromDate,
    this.toDate,
    this.viewMode = 'audit',
  });

  GLLoaded copyWith({
    List<GeneralLedgerEntryModel>? entries,
    int? totalCount,
    bool? isFromCache,
    bool? isLoadMore,
    int? pageNumber,
    int? pageSize,
    bool? hasReachedMax,
    List<String>? transactionTypes,
    List<String>? referenceTypes,
    List<String>? moneyChannels,
    DateTime? fromDate,
    DateTime? toDate,
    String? viewMode,
  }) {
    return GLLoaded(
      entries: entries ?? this.entries,
      totalCount: totalCount ?? this.totalCount,
      isFromCache: isFromCache ?? this.isFromCache,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      transactionTypes: transactionTypes ?? this.transactionTypes,
      referenceTypes: referenceTypes ?? this.referenceTypes,
      moneyChannels: moneyChannels ?? this.moneyChannels,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [
        entries,
        totalCount,
        isFromCache,
        isLoadMore,
        pageNumber,
        pageSize,
        hasReachedMax,
        transactionTypes,
        referenceTypes,
        moneyChannels,
        fromDate,
        toDate,
        viewMode,
      ];
}

class GLError extends GLState {
  final String message;
  final List<GeneralLedgerEntryModel>? previousEntries;

  const GLError(this.message, {this.previousEntries});

  @override
  List<Object?> get props => [message, previousEntries];
}
