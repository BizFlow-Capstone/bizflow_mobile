class HomeAiForecastItemDto {
  final String forecastDate;
  final double predictedRevenue;
  final double lowerBound;
  final double upperBound;
  final String? trendNote;

  const HomeAiForecastItemDto({
    required this.forecastDate,
    required this.predictedRevenue,
    required this.lowerBound,
    required this.upperBound,
    this.trendNote,
  });

  factory HomeAiForecastItemDto.fromJson(Map<String, dynamic> json) {
    return HomeAiForecastItemDto(
      forecastDate: json['forecastDate']?.toString() ?? '',
      predictedRevenue: (json['predictedRevenue'] as num?)?.toDouble() ?? 0,
      lowerBound: (json['lowerBound'] as num?)?.toDouble() ?? 0,
      upperBound: (json['upperBound'] as num?)?.toDouble() ?? 0,
      trendNote: json['trendNote']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forecastDate': forecastDate,
      'predictedRevenue': predictedRevenue,
      'lowerBound': lowerBound,
      'upperBound': upperBound,
      'trendNote': trendNote,
    };
  }
}

class HomeAiInsightItemDto {
  final String productId;
  final String? productName;
  final String insightType;
  final int rank;
  final double metricValue;
  final int periodDays;

  const HomeAiInsightItemDto({
    required this.productId,
    this.productName,
    required this.insightType,
    required this.rank,
    required this.metricValue,
    required this.periodDays,
  });

  factory HomeAiInsightItemDto.fromJson(Map<String, dynamic> json) {
    return HomeAiInsightItemDto(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString(),
      insightType: json['insightType']?.toString() ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      metricValue: (json['metricValue'] as num?)?.toDouble() ?? 0,
      periodDays: (json['periodDays'] as num?)?.toInt() ?? 0,
    );
  }

  HomeAiInsightItemDto copyWith({
    String? productId,
    String? productName,
    String? insightType,
    int? rank,
    double? metricValue,
    int? periodDays,
  }) {
    return HomeAiInsightItemDto(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      insightType: insightType ?? this.insightType,
      rank: rank ?? this.rank,
      metricValue: metricValue ?? this.metricValue,
      periodDays: periodDays ?? this.periodDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'insightType': insightType,
      'rank': rank,
      'metricValue': metricValue,
      'periodDays': periodDays,
    };
  }
}

class HomeAiAnomalyItemDto {
  final String id;
  final String alertType;
  final String severity;
  final String description;
  final String? referenceId;
  final String? recordType;
  final bool isAcknowledged;
  final String referenceDate;

  const HomeAiAnomalyItemDto({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.description,
    this.referenceId,
    this.recordType,
    required this.isAcknowledged,
    required this.referenceDate,
  });

  factory HomeAiAnomalyItemDto.fromJson(Map<String, dynamic> json) {
    return HomeAiAnomalyItemDto(
      id: json['id']?.toString() ?? '',
      alertType: json['alertType']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      referenceId: json['referenceId']?.toString(),
      recordType: json['recordType']?.toString(),
      isAcknowledged: json['isAcknowledged'] == true,
      referenceDate: json['referenceDate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alertType': alertType,
      'severity': severity,
      'description': description,
      'referenceId': referenceId,
      'recordType': recordType,
      'isAcknowledged': isAcknowledged,
      'referenceDate': referenceDate,
    };
  }
}

class HomeAiReorderItemDto {
  final String productId;
  final double currentStock;
  final int daysUntilStockout;
  final double suggestedQuantity;
  final double avgDailySales;
  final String urgency;
  final String generatedAt;

  const HomeAiReorderItemDto({
    required this.productId,
    required this.currentStock,
    required this.daysUntilStockout,
    required this.suggestedQuantity,
    required this.avgDailySales,
    required this.urgency,
    required this.generatedAt,
  });

  factory HomeAiReorderItemDto.fromJson(Map<String, dynamic> json) {
    return HomeAiReorderItemDto(
      productId: json['productId']?.toString() ?? '',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
      daysUntilStockout: (json['daysUntilStockout'] as num?)?.toInt() ?? 0,
      suggestedQuantity: (json['suggestedQuantity'] as num?)?.toDouble() ?? 0,
      avgDailySales: (json['avgDailySales'] as num?)?.toDouble() ?? 0,
      urgency: json['urgency']?.toString() ?? '',
      generatedAt: json['generatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'currentStock': currentStock,
      'daysUntilStockout': daysUntilStockout,
      'suggestedQuantity': suggestedQuantity,
      'avgDailySales': avgDailySales,
      'urgency': urgency,
      'generatedAt': generatedAt,
    };
  }
}

class HomeAiBundleDto {
  final List<HomeAiForecastItemDto> forecasts;
  final List<HomeAiReorderItemDto> reorders;
  final List<HomeAiInsightItemDto> insights;
  final List<HomeAiAnomalyItemDto> anomalies;

  const HomeAiBundleDto({
    required this.forecasts,
    required this.reorders,
    required this.insights,
    required this.anomalies,
  });

  bool get hasAnyData =>
      forecasts.isNotEmpty ||
      reorders.isNotEmpty ||
      insights.isNotEmpty ||
      anomalies.isNotEmpty;

  factory HomeAiBundleDto.fromJson(Map<String, dynamic> json) {
    final forecastJson = (json['forecasts'] as List<dynamic>? ?? const []);
    final reorderJson = (json['reorders'] as List<dynamic>? ?? const []);
    final insightJson = (json['insights'] as List<dynamic>? ?? const []);
    final anomalyJson = (json['anomalies'] as List<dynamic>? ?? const []);

    return HomeAiBundleDto(
      forecasts: forecastJson
          .whereType<Map<String, dynamic>>()
          .map(HomeAiForecastItemDto.fromJson)
          .toList(),
      reorders: reorderJson
          .whereType<Map<String, dynamic>>()
          .map(HomeAiReorderItemDto.fromJson)
          .toList(),
      insights: insightJson
          .whereType<Map<String, dynamic>>()
          .map(HomeAiInsightItemDto.fromJson)
          .toList(),
      anomalies: anomalyJson
          .whereType<Map<String, dynamic>>()
          .map(HomeAiAnomalyItemDto.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forecasts': forecasts.map((e) => e.toJson()).toList(),
      'reorders': reorders.map((e) => e.toJson()).toList(),
      'insights': insights.map((e) => e.toJson()).toList(),
      'anomalies': anomalies.map((e) => e.toJson()).toList(),
    };
  }
}
