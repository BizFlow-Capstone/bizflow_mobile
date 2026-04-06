class SubscriptionPlanPriceDto {
  final int priceId;
  final double basePrice;
  final double? discountedPrice;
  final double effectivePrice;
  final String? discountStart;
  final String? discountEnd;
  final bool isDiscountActive;
  final String currency;

  SubscriptionPlanPriceDto({
    required this.priceId,
    required this.basePrice,
    this.discountedPrice,
    required this.effectivePrice,
    this.discountStart,
    this.discountEnd,
    required this.isDiscountActive,
    required this.currency,
  });

  factory SubscriptionPlanPriceDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanPriceDto(
      priceId: json['priceId'] as int,
      basePrice: (json['basePrice'] as num).toDouble(),
      discountedPrice: json['discountedPrice'] != null ? (json['discountedPrice'] as num).toDouble() : null,
      effectivePrice: (json['effectivePrice'] as num).toDouble(),
      discountStart: json['discountStart'] as String?,
      discountEnd: json['discountEnd'] as String?,
      isDiscountActive: json['isDiscountActive'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  Map<String, dynamic> toJson() => {
        'priceId': priceId,
        'basePrice': basePrice,
        'discountedPrice': discountedPrice,
        'effectivePrice': effectivePrice,
        'discountStart': discountStart,
        'discountEnd': discountEnd,
        'isDiscountActive': isDiscountActive,
        'currency': currency,
      };
}

class PlanFeatureDto {
  final int featureId;
  final String featureCode;
  final String featureName;
  final int usageLimit; // The maximum limit defined by the plan

  PlanFeatureDto({
    required this.featureId,
    required this.featureCode,
    required this.featureName,
    required this.usageLimit,
  });

  factory PlanFeatureDto.fromJson(Map<String, dynamic> json) {
    return PlanFeatureDto(
      featureId: json['featureId'] as int? ?? 0,
      featureCode: json['featureCode'] as String? ?? '',
      featureName: json['featureName'] as String? ?? '',
      usageLimit: json['usageLimit'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'featureId': featureId,
        'featureCode': featureCode,
        'featureName': featureName,
        'usageLimit': usageLimit,
      };
}

class SubscriptionPlanDto {
  final int subscriptionPlanId;
  final String name;
  final String? description;
  final int durationDays;
  final SubscriptionPlanPriceDto? currentPrice;
  final List<PlanFeatureDto> features;

  SubscriptionPlanDto({
    required this.subscriptionPlanId,
    required this.name,
    this.description,
    required this.durationDays,
    this.currentPrice,
    required this.features,
  });

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanDto(
      subscriptionPlanId: json['subscriptionPlanId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      durationDays: json['durationDays'] as int? ?? 0,
      currentPrice: json['currentPrice'] != null
          ? SubscriptionPlanPriceDto.fromJson(json['currentPrice'] as Map<String, dynamic>)
          : null,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => PlanFeatureDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'subscriptionPlanId': subscriptionPlanId,
        'name': name,
        'description': description,
        'durationDays': durationDays,
        'currentPrice': currentPrice?.toJson(),
        'features': features.map((e) => e.toJson()).toList(),
      };
}

class CurrentSubscriptionDto {
  final String? subscriptionId;
  final String status;
  final String? startDate;
  final String? endDate;
  final SubscriptionPlanDto? plan;

  bool get isActive => status == 'active';

  CurrentSubscriptionDto({
    this.subscriptionId,
    required this.status,
    this.startDate,
    this.endDate,
    this.plan,
  });

  factory CurrentSubscriptionDto.fromJson(Map<String, dynamic> json) {
    return CurrentSubscriptionDto(
      subscriptionId: json['subscriptionId'] as String?,
      status: (json['status'] as String? ?? 'inactive').trim().toLowerCase(),
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      plan: json['plan'] != null
          ? SubscriptionPlanDto.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'subscriptionId': subscriptionId,
        'status': status,
        'startDate': startDate,
        'endDate': endDate,
        'plan': plan?.toJson(),
      };
}

class CheckoutSessionResponseDto {
  final String transactionId;
  final String sessionUrl;
  final double planPrice;
  final double prorationCredit;
  final double finalAmount;
  final String currency;
  final String transactionType;

  CheckoutSessionResponseDto({
    required this.transactionId,
    required this.sessionUrl,
    required this.planPrice,
    required this.prorationCredit,
    required this.finalAmount,
    required this.currency,
    required this.transactionType,
  });

  factory CheckoutSessionResponseDto.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionResponseDto(
      transactionId: json['transactionId'] as String? ?? '',
      sessionUrl: json['sessionUrl'] as String? ?? '',
      planPrice: (json['planPrice'] as num?)?.toDouble() ?? 0.0,
      prorationCredit: (json['prorationCredit'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'VND',
      transactionType: json['transactionType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'sessionUrl': sessionUrl,
        'planPrice': planPrice,
        'prorationCredit': prorationCredit,
        'finalAmount': finalAmount,
        'currency': currency,
        'transactionType': transactionType,
      };
}

/// Single payment transaction record from /api/subscriptions/transactions.
class SubscriptionTransactionDto {
  final String transactionId;
  final String transactionType; // e.g. 'NEW', 'RENEWAL', 'UPGRADE'
  final String status;          // e.g. 'PAID', 'PENDING', 'FAILED'
  final double amount;
  final String currency;
  final String? planName;
  final String? createdAt;
  final String? paidAt;

  SubscriptionTransactionDto({
    required this.transactionId,
    required this.transactionType,
    required this.status,
    required this.amount,
    required this.currency,
    this.planName,
    this.createdAt,
    this.paidAt,
  });

  factory SubscriptionTransactionDto.fromJson(Map<String, dynamic> json) {
    final resolvedAmount =
        (json['amount'] as num?)?.toDouble() ??
        (json['finalAmount'] as num?)?.toDouble() ??
        (json['planPrice'] as num?)?.toDouble() ??
        0.0;

    return SubscriptionTransactionDto(
      transactionId: json['transactionId'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: resolvedAmount,
      currency: json['currency'] as String? ?? 'VND',
      planName: json['planName'] as String?,
      createdAt: json['createdAt'] as String?,
      paidAt: json['paidAt'] as String?,
    );
  }
}

/// Paged response wrapper for transaction list.
class PagedTransactionsDto {
  final List<SubscriptionTransactionDto> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  PagedTransactionsDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PagedTransactionsDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedTransactionsDto(
      items: rawItems
          .map((e) =>
              SubscriptionTransactionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? rawItems.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? rawItems.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  factory PagedTransactionsDto.fromUnknown(dynamic raw) {
    if (raw is List) {
      final items = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(SubscriptionTransactionDto.fromJson)
          .toList();
      return PagedTransactionsDto(
        items: items,
        totalCount: items.length,
        page: 1,
        pageSize: items.length,
        hasMore: false,
      );
    }

    if (raw is Map<String, dynamic>) {
      return PagedTransactionsDto.fromJson(raw);
    }

    if (raw is Map) {
      return PagedTransactionsDto.fromJson(Map<String, dynamic>.from(raw));
    }

    return PagedTransactionsDto(
      items: const [],
      totalCount: 0,
      page: 1,
      pageSize: 0,
      hasMore: false,
    );
  }
}
