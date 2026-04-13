import 'package:equatable/equatable.dart';

abstract class GLEvent extends Equatable {
  const GLEvent();

  @override
  List<Object?> get props => [];
}

class LoadGLEntriesRequested extends GLEvent {
  final int businessLocationId;
  final int pageNumber;
  final int pageSize;
  final List<String>? transactionTypes;
  final List<String>? referenceTypes;
  final List<String>? moneyChannels;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String viewMode;
  final bool isLoadMore;

  const LoadGLEntriesRequested({
    required this.businessLocationId,
    required this.pageNumber,
    required this.pageSize,
    this.transactionTypes,
    this.referenceTypes,
    this.moneyChannels,
    this.fromDate,
    this.toDate,
    this.viewMode = 'audit',
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [
        businessLocationId,
        pageNumber,
        pageSize,
        transactionTypes,
        referenceTypes,
        moneyChannels,
        fromDate,
        toDate,
        viewMode,
        isLoadMore,
      ];
}

class ChangeGLFiltersRequested extends GLEvent {
  final List<String>? transactionTypes;
  final List<String>? referenceTypes;
  final List<String>? moneyChannels;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? viewMode;

  const ChangeGLFiltersRequested({
    this.transactionTypes,
    this.referenceTypes,
    this.moneyChannels,
    this.fromDate,
    this.toDate,
    this.viewMode,
  });

  @override
  List<Object?> get props => [
        transactionTypes,
        referenceTypes,
        moneyChannels,
        fromDate,
        toDate,
        viewMode,
      ];
}

class SearchGLEntriesRequested extends GLEvent {
  final String keyword;

  const SearchGLEntriesRequested(this.keyword);

  @override
  List<Object?> get props => [keyword];
}
