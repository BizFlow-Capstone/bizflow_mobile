class AiDraftCostItemDto {
  final double? amount;
  final String? description;
  final String? costDate;
  final String? costType;
  final String? paymentMethod;

  const AiDraftCostItemDto({
    this.amount,
    this.description,
    this.costDate,
    this.costType,
    this.paymentMethod,
  });

  factory AiDraftCostItemDto.fromJson(Map<String, dynamic> json) {
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

    return AiDraftCostItemDto(
      amount: asDouble(json['amount']),
      description: asString(json['description']),
      costDate: asString(json['costDate'] ?? json['cost_date']),
      costType: asString(json['costType'] ?? json['cost_type']),
      paymentMethod: asString(json['paymentMethod'] ?? json['payment_method']),
    );
  }
}

class AiDraftCostResultDto {
  final List<AiDraftCostItemDto> items;
  final String rawTranscript;
  final String confidence;

  const AiDraftCostResultDto({
    required this.items,
    required this.rawTranscript,
    required this.confidence,
  });

  factory AiDraftCostResultDto.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawItems = data['items'];
    final parsedItems = <AiDraftCostItemDto>[];

    if (rawItems is List) {
      parsedItems.addAll(
        rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(AiDraftCostItemDto.fromJson),
      );
    }

    // Backward-compatible: some endpoints return a single draft object instead of items[]
    if (parsedItems.isEmpty) {
      final hasSingleDraftFields =
          data['amount'] != null ||
          data['description'] != null ||
          data['costType'] != null ||
          data['cost_type'] != null ||
          data['paymentMethod'] != null ||
          data['payment_method'] != null;

      if (hasSingleDraftFields) {
        parsedItems.add(
          AiDraftCostItemDto.fromJson({
            'amount': data['amount'],
            'description': data['description'],
            'costDate': data['costDate'] ?? data['cost_date'],
            'costType': data['costType'] ?? data['cost_type'],
            'paymentMethod': data['paymentMethod'] ?? data['payment_method'],
          }),
        );
      }
    }

    return AiDraftCostResultDto(
      items: parsedItems,
      rawTranscript:
          (data['rawTranscript'] ?? data['raw_transcript'] ?? '').toString(),
      confidence: (data['confidence'] ?? 'low').toString(),
    );
  }
}
