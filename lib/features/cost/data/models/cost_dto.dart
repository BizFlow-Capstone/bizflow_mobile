import 'package:equatable/equatable.dart';
import '../../../../shared/utils/date_formatter.dart';

import '../../../../core/reference/data/reference_item.dart';

class CostDto extends Equatable {
  final int costId;
  final int businessLocationId;
  final String costType;
  final String? costTypeLabel;
  final double amount;
  final DateTime costDate;
  final DateTime? documentDate;
  final String description;
  final String? paymentMethod;
  final String? paymentMethodLabel;
  final String? documentUrl;
  final String? referenceType;
  final int? referenceId;
  final String? documentNumber;
  final String? referenceCode;
  final String? statusCode;
  final String? statusLabel;
  final String createdBy;
  final String? imagePath;
  final DateTime createdAt;

  const CostDto({
    required this.costId,
    required this.businessLocationId,
    required this.costType,
    this.costTypeLabel,
    required this.amount,
    required this.costDate,
    this.documentDate,
    required this.description,
    this.paymentMethod,
    this.paymentMethodLabel,
    this.documentUrl,
    this.referenceType,
    this.referenceId,
    this.documentNumber,
    this.referenceCode,
    this.statusCode,
    this.statusLabel,
    this.imagePath,
    required this.createdBy,
    required this.createdAt,
  });

  factory CostDto.fromJson(Map<String, dynamic> json) {
    final source = json['source'] is Map<String, dynamic>
      ? json['source'] as Map<String, dynamic>
      : const <String, dynamic>{};

    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    int? firstPositiveNullableInt(List<dynamic> values) {
      int? fallback;
      for (final value in values) {
        final parsed = asNullableInt(value);
        if (parsed == null) continue;
        fallback ??= parsed;
        if (parsed > 0) {
          return parsed;
        }
      }
      if (fallback != null && fallback > 0) {
        return fallback;
      }
      return null;
    }

    String? asNullableString(dynamic value) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return null;
      return normalized;
    }

    String asString(dynamic value, {String fallback = ''}) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return fallback;
      return normalized;
    }

    final rawStatus =
        json['status'] is Map<String, dynamic>
            ? json['status'] as Map<String, dynamic>
            : source['status'] is Map<String, dynamic>
            ? source['status'] as Map<String, dynamic>
            : const <String, dynamic>{};

    final documentNumber = asNullableString(
      json['documentNumber'] ??
          json['DocumentNumber'] ??
          json['voucherNo'] ??
          json['VoucherNo'] ??
          source['documentNumber'] ??
          source['DocumentNumber'] ??
          source['voucherNo'] ??
          source['VoucherNo'],
    );

    return CostDto(
      costId: asInt(json['costId'] ?? json['id']),
      businessLocationId: asInt(json['businessLocationId']),
      costType: referenceCodeFromDynamic(json['costType']),
      costTypeLabel: referenceLabelFromDynamic(json['costType']),
      amount: asDouble(json['amount']),
      costDate:
          DateFormatter.parseApiDateTime(asNullableString(json['costDate'])) ??
          DateTime.now(),
      documentDate: DateFormatter.parseApiDateTime(
        asNullableString(json['documentDate']),
      ),
      description: asString(json['description']),
      paymentMethod: referenceCodeFromDynamic(
        json['paymentMethod'] ?? json['PaymentMethod'],
      ).isEmpty
          ? null
          : referenceCodeFromDynamic(
              json['paymentMethod'] ?? json['PaymentMethod'],
            ),
      paymentMethodLabel: referenceLabelFromDynamic(
        json['paymentMethod'] ?? json['PaymentMethod'],
      ),
      documentUrl: asNullableString(
        json['documentUrl'] ??
        json['DocumentUrl'] ??
        source['documentUrl'] ??
        source['DocumentUrl'] ??
        json['imageUrl'] ??
        json['ImageUrl'] ??
        source['imageUrl'] ??
        source['ImageUrl'] ??
        json['receiptImageUrl'] ??
        json['ReceiptImageUrl'] ??
        source['receiptImageUrl'] ??
        source['ReceiptImageUrl'],
      ),
      referenceType: asNullableString(
        json['entityType'] ??
          json['EntityType'] ??
          source['entityType'] ??
          source['EntityType'] ??
          json['referenceType'] ??
          json['ReferenceType'] ??
            source['referenceType'] ??
          source['ReferenceType'],
      ),
      referenceId: firstPositiveNullableInt([
        json['importId'],
        json['ImportId'],
        json['stockImportId'],
        json['StockImportId'],
        source['importId'],
        source['ImportId'],
        source['stockImportId'],
        source['StockImportId'],
        json['orderId'],
        json['OrderId'],
        source['orderId'],
        source['OrderId'],
        json['referenceId'],
        json['ReferenceId'],
        source['referenceId'],
        source['ReferenceId'],
        json['entityId'],
        json['EntityId'],
        source['entityId'],
        source['EntityId'],
      ]),
      referenceCode: asNullableString(
        json['referenceCode'] ??
            json['ReferenceCode'] ??
            json['code'] ??
            json['Code'] ??
            json['importCode'] ??
            json['ImportCode'] ??
            json['orderCode'] ??
            json['OrderCode'] ??
            source['referenceCode'] ??
            source['ReferenceCode'] ??
            source['code'] ??
            source['Code'] ??
            source['importCode'] ??
            source['ImportCode'] ??
            source['orderCode'] ??
            source['OrderCode'],
      ),
      documentNumber: documentNumber,
      statusCode: asNullableString(
        rawStatus['code'] ?? rawStatus['Code'] ?? json['statusCode'] ?? json['StatusCode'],
      ),
      statusLabel: asNullableString(
        rawStatus['label'] ?? rawStatus['Label'] ?? json['statusLabel'] ?? json['StatusLabel'],
      ),
      imagePath: asNullableString(
        json['imagePath'] ??
            json['ImagePath'] ??
            source['imagePath'] ??
            source['ImagePath'] ??
            json['imageUrl'] ??
            json['ImageUrl'] ??
            source['imageUrl'] ??
            source['ImageUrl'] ??
            json['receiptImageUrl'] ??
            json['ReceiptImageUrl'] ??
            source['receiptImageUrl'] ??
            source['ReceiptImageUrl'] ??
            json['documentUrl'] ??
            json['DocumentUrl'] ??
            source['documentUrl'] ??
            source['DocumentUrl'] ??
            json['documentImageUrl'] ??
            json['DocumentImageUrl'] ??
            source['documentImageUrl'] ??
            source['DocumentImageUrl'],
      ),
      createdBy: asString(json['createdBy'] ?? source['createdBy']),
      createdAt:
          DateFormatter.parseApiDateTime(asNullableString(json['createdAt'])) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'costId': costId,
      'businessLocationId': businessLocationId,
      'costType': costType,
      'amount': amount,
      'costDate': costDate.toIso8601String(),
      'documentDate': documentDate?.toIso8601String(),
      'description': description,
      'paymentMethod': paymentMethod,
      'documentUrl': documentUrl,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'referenceCode': referenceCode,
      'documentNumber': documentNumber,
      'statusCode': statusCode,
      'statusLabel': statusLabel,
      'imagePath': imagePath,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    costId,
    businessLocationId,
    costType,
    amount,
    costDate,
    documentDate,
    description,
    paymentMethod,
    documentUrl,
    referenceType,
    referenceId,
    documentNumber,
    referenceCode,
    statusCode,
    statusLabel,
    imagePath,
    createdBy,
    createdAt,
  ];
}

class CostResponseDto extends Equatable {
  final List<CostDto> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  const CostResponseDto({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  factory CostResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CostResponseDto(
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => CostDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: data['totalCount'] as int? ?? 0,
      pageNumber: data['pageNumber'] as int? ?? 1,
      pageSize: data['pageSize'] as int? ?? 20,
    );
  }

  @override
  List<Object?> get props => [items, totalCount, pageNumber, pageSize];
}
