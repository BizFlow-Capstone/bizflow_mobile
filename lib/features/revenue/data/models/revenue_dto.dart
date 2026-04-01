import 'package:equatable/equatable.dart';
import '../../../../shared/utils/date_formatter.dart';

class RevenueDto extends Equatable {
  final int revenueId;
  final int businessLocationId;
  final String revenueType;
  final double amount;
  final DateTime revenueDate;
  final DateTime? documentDate;
  final String description;
  final String? moneyChannel;
  final String? referenceType;
  final int? referenceId;
  final String? referenceCode;
  final String? businessTypeId;
  final String? businessTypeName;
  final String createdBy;
  final DateTime createdAt;

  const RevenueDto({
    required this.revenueId,
    required this.businessLocationId,
    required this.revenueType,
    required this.amount,
    required this.revenueDate,
    this.documentDate,
    required this.description,
    this.moneyChannel,
    this.referenceType,
    this.referenceId,
    this.referenceCode,
    this.businessTypeId,
    this.businessTypeName,
    required this.createdBy,
    required this.createdAt,
  });

  factory RevenueDto.fromJson(Map<String, dynamic> json) {
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

    return RevenueDto(
      revenueId: asInt(json['revenueId'] ?? json['id']),
      businessLocationId: asInt(json['businessLocationId']),
      revenueType: json['revenueType'] as String? ?? '',
      amount: asDouble(json['amount']),
      revenueDate:
          DateFormatter.parseApiDateTime(json['revenueDate'] as String?) ??
          DateTime.now(),
      documentDate: DateFormatter.parseApiDateTime(
        json['documentDate'] as String?,
      ),
      description: json['description'] as String? ?? '',
      moneyChannel: asNullableString(json['moneyChannel']),
      referenceType: asNullableString(json['referenceType']),
      referenceId: asNullableInt(json['referenceId']),
      referenceCode: asNullableString(json['referenceCode']),
      businessTypeId: asNullableString(
        json['businessTypeId'] ?? json['BusinessTypeId'],
      ),
      businessTypeName: asNullableString(
        json['businessTypeName'] ?? json['BusinessTypeName'],
      ),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt:
          DateFormatter.parseApiDateTime(json['createdAt'] as String?) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenueId': revenueId,
      'businessLocationId': businessLocationId,
      'revenueType': revenueType,
      'amount': amount,
      'revenueDate': revenueDate.toIso8601String(),
      'documentDate': documentDate?.toIso8601String(),
      'description': description,
      'moneyChannel': moneyChannel,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'referenceCode': referenceCode,
      'businessTypeId': businessTypeId,
      'businessTypeName': businessTypeName,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    revenueId,
    businessLocationId,
    revenueType,
    amount,
    revenueDate,
    documentDate,
    description,
    moneyChannel,
    referenceType,
    referenceId,
    referenceCode,
    businessTypeId,
    businessTypeName,
    createdBy,
    createdAt,
  ];
}

class RevenueResponseDto extends Equatable {
  final List<RevenueDto> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  const RevenueResponseDto({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  factory RevenueResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RevenueResponseDto(
      items:
          (data['items'] as List<dynamic>?)
              ?.map((e) => RevenueDto.fromJson(e as Map<String, dynamic>))
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
