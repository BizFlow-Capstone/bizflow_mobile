class AiDraftOrderItemDto {
  final String? productId;
  final int? saleItemId;
  final String? productName;
  final bool matched;
  final int quantity;
  final String? unit;
  final double? unitPrice;
  final double? lineTotal;
  final String? customerName;
  final bool isDebt;

  const AiDraftOrderItemDto({
    this.productId,
    this.saleItemId,
    this.productName,
    required this.matched,
    required this.quantity,
    this.unit,
    this.unitPrice,
    this.lineTotal,
    this.customerName,
    required this.isDebt,
  });

  factory AiDraftOrderItemDto.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    bool asBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return fallback;
    }

    String? asString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    return AiDraftOrderItemDto(
      productId: asString(json['productId'] ?? json['product_id']),
      saleItemId: asNullableInt(json['saleItemId'] ?? json['sale_item_id']),
      productName: asString(json['productName'] ?? json['product_name']),
      matched: asBool(json['matched']),
      quantity: asInt(json['quantity'], fallback: 1).clamp(1, 1000000),
      unit: asString(json['unit']),
      unitPrice: asDouble(json['unitPrice'] ?? json['unit_price']),
      lineTotal: asDouble(json['lineTotal'] ?? json['line_total']),
      customerName: asString(json['customerName'] ?? json['customer_name']),
      isDebt: asBool(json['isDebt'] ?? json['is_debt']),
    );
  }
}

class AiDraftOrderResultDto {
  final List<AiDraftOrderItemDto> items;
  final String rawTranscript;
  final String confidence;
  final double? totalAmount;

  const AiDraftOrderResultDto({
    required this.items,
    required this.rawTranscript,
    required this.confidence,
    this.totalAmount,
  });

  factory AiDraftOrderResultDto.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawItems = data['items'];
    final parsedItems = <AiDraftOrderItemDto>[];

    if (rawItems is List) {
      parsedItems.addAll(
        rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(AiDraftOrderItemDto.fromJson),
      );
    }

    return AiDraftOrderResultDto(
      items: parsedItems,
      rawTranscript: (data['rawTranscript'] ?? data['raw_transcript'] ?? '')
          .toString(),
      confidence: (data['confidence'] ?? 'low').toString(),
      totalAmount: asDouble(data['totalAmount'] ?? data['total_amount']),
    );
  }
}
