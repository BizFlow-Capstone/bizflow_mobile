import 'package:equatable/equatable.dart';

import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/entities/debtor_entity.dart';

enum DebtorStatus { initial, loading, success, loadingMore, failure }

class DebtorState extends Equatable {
  final DebtorStatus status;
  final List<DebtorEntity> debtors;
  final List<DebtorEntity> activeDebtorsByLocation;
  final DebtorEntity? debtorDetail;
  final List<DebtPaymentEntity> paymentHistory;
  final bool hasReachedMax;
  final int currentPage;
  final int totalCount;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final String? search;
  final bool? isActive;
  final List<int>? businessLocationIds;
  final String? lastMessageCode;

  const DebtorState({
    this.status = DebtorStatus.initial,
    this.debtors = const [],
    this.activeDebtorsByLocation = const [],
    this.debtorDetail,
    this.paymentHistory = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.search,
    this.isActive,
    this.businessLocationIds,
    this.lastMessageCode,
  });

  static const Object _isActiveSentinel = Object();

  DebtorState copyWith({
    DebtorStatus? status,
    List<DebtorEntity>? debtors,
    List<DebtorEntity>? activeDebtorsByLocation,
    DebtorEntity? debtorDetail,
    List<DebtPaymentEntity>? paymentHistory,
    bool? hasReachedMax,
    int? currentPage,
    int? totalCount,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    String? search,
    Object? isActive = _isActiveSentinel,
    List<int>? businessLocationIds,
    String? lastMessageCode,
  }) {
    return DebtorState(
      status: status ?? this.status,
      debtors: debtors ?? this.debtors,
      activeDebtorsByLocation:
          activeDebtorsByLocation ?? this.activeDebtorsByLocation,
      debtorDetail: debtorDetail ?? this.debtorDetail,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
      search: search ?? this.search,
      isActive: identical(isActive, _isActiveSentinel)
          ? this.isActive
          : isActive as bool?,
      businessLocationIds: businessLocationIds ?? this.businessLocationIds,
      lastMessageCode: lastMessageCode,
    );
  }

  @override
  List<Object?> get props => [
    status,
    debtors,
    activeDebtorsByLocation,
    debtorDetail,
    paymentHistory,
    hasReachedMax,
    currentPage,
    totalCount,
    isSubmitting,
    errorMessage,
    successMessage,
    search,
    isActive,
    businessLocationIds,
    lastMessageCode,
  ];
}
