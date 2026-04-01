import 'package:equatable/equatable.dart';
import '../../../../shared/utils/date_formatter.dart';

class CostDto extends Equatable {
  final int costId;
  final int businessLocationId;
  final String costType;
  final double amount;
  final DateTime costDate;
  final DateTime? documentDate;
  final String description;
  final String? paymentMethod;
  final String? documentUrl;
  final String? referenceType;
  final int? referenceId;
  final String? referenceCode;
  final String createdBy;
  final DateTime createdAt;

  const CostDto({
    required this.costId,
    required this.businessLocationId,
    required this.costType,
    required this.amount,
    required this.costDate,
    this.documentDate,
    required this.description,
    this.paymentMethod,
    this.documentUrl,
    this.referenceType,
    this.referenceId,
    this.referenceCode,
    required this.createdBy,
    required this.createdAt,
  });

  factory CostDto.fromJson(Map<String, dynamic> json) {
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

    String? asNullableString(dynamic value) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return null;
      return normalized;
    }

    return CostDto(
      costId: asInt(json['costId'] ?? json['id']),
      businessLocationId: asInt(json['businessLocationId']),
      costType: json['costType'] as String? ?? '',
      amount: asDouble(json['amount']),
      costDate:
          DateFormatter.parseApiDateTime(json['costDate'] as String?) ??
          DateTime.now(),
      documentDate: DateFormatter.parseApiDateTime(
        json['documentDate'] as String?,
      ),
      description: json['description'] as String? ?? '',
      paymentMethod: asNullableString(json['paymentMethod']),
      documentUrl: asNullableString(json['documentUrl']),
      referenceType: asNullableString(json['referenceType']),
      referenceId: asNullableInt(json['referenceId']),
      referenceCode: asNullableString(json['referenceCode']),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt:
          DateFormatter.parseApiDateTime(json['createdAt'] as String?) ??
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
    referenceCode,
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
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CostDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? 0,
      pageNumber: data['pageNumber'] as int? ?? 1,
      pageSize: data['pageSize'] as int? ?? 20,
    );
  }

  @override
  List<Object?> get props => [items, totalCount, pageNumber, pageSize];
}
