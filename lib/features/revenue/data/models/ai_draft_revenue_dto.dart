class AiDraftRevenueItemDto {
  final double? amount;
  final String? description;
  final String? revenueDate;
  final String? moneyChannel;

  const AiDraftRevenueItemDto({
    this.amount,
    this.description,
    this.revenueDate,
    this.moneyChannel,
  });

  factory AiDraftRevenueItemDto.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    String? asString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    return AiDraftRevenueItemDto(
      amount: asDouble(json['amount']),
      description: asString(json['description']),
      revenueDate: asString(json['revenueDate'] ?? json['revenue_date']),
      moneyChannel: asString(json['moneyChannel'] ?? json['money_channel']),
    );
  }
}

class AiDraftRevenueResultDto {
  final List<AiDraftRevenueItemDto> items;
  final String rawTranscript;
  final String confidence;

  const AiDraftRevenueResultDto({
    required this.items,
    required this.rawTranscript,
    required this.confidence,
  });

  factory AiDraftRevenueResultDto.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawItems = data['items'] as List<dynamic>? ?? const <dynamic>[];

    return AiDraftRevenueResultDto(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(AiDraftRevenueItemDto.fromJson)
          .toList(),
      rawTranscript:
          (data['rawTranscript'] ?? data['raw_transcript'] ?? '').toString(),
      confidence: (data['confidence'] ?? 'low').toString(),
    );
  }
}
