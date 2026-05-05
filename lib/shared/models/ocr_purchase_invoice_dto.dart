class OcrPurchaseInvoiceItemDto {
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;

  const OcrPurchaseInvoiceItemDto({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  factory OcrPurchaseInvoiceItemDto.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final normalized = value.replaceAll(',', '').trim();
        return double.tryParse(normalized) ?? fallback;
      }
      return fallback;
    }

    return OcrPurchaseInvoiceItemDto(
      productName: (json['productName'] ?? json['product_name'] ?? '')
          .toString()
          .trim(),
      quantity: asDouble(json['quantity'], fallback: 0),
      unit: (json['unit'] ?? '').toString().trim(),
      unitPrice: asDouble(json['unitPrice'] ?? json['unit_price']),
    );
  }
}

class OcrPurchaseInvoiceResultDto {
  final String? supplierName;
  final String? invoiceDate;
  final List<OcrPurchaseInvoiceItemDto> items;
  final double? totalAmount;
  final String confidence;

  const OcrPurchaseInvoiceResultDto({
    this.supplierName,
    this.invoiceDate,
    required this.items,
    this.totalAmount,
    required this.confidence,
  });

  factory OcrPurchaseInvoiceResultDto.fromJson(Map<String, dynamic> json) {
    double? asNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final normalized = value.replaceAll(',', '').trim();
        return double.tryParse(normalized);
      }
      return null;
    }

    String? asNullableString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawItems = data['items'];
    final items = <OcrPurchaseInvoiceItemDto>[];

    if (rawItems is List) {
      items.addAll(
        rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(OcrPurchaseInvoiceItemDto.fromJson),
      );
    }

    return OcrPurchaseInvoiceResultDto(
      supplierName: asNullableString(
        data['supplierName'] ?? data['supplier_name'],
      ),
      invoiceDate: asNullableString(
        data['invoiceDate'] ?? data['invoice_date'],
      ),
      items: items,
      totalAmount: asNullableDouble(
        data['totalAmount'] ?? data['total_amount'],
      ),
      confidence: (data['confidence'] ?? 'low').toString().trim(),
    );
  }
}
