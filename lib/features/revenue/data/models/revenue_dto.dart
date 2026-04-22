import 'package:equatable/equatable.dart';
import '../../../../shared/utils/date_formatter.dart';

import '../../../../core/reference/data/reference_item.dart';

class RevenueDto extends Equatable {
  final int revenueId;
  final int businessLocationId;
  final String revenueType;
  final double amount;
  final DateTime revenueDate;
  final DateTime? documentDate;
  final String description;
  final String? moneyChannel;
  final String? moneyChannelLabel;
  final String? referenceType;
  final int? referenceId;
  final String? referenceCode;
  final String? businessTypeId;
  final String? businessTypeName;
  final String createdBy;
  final String? imagePath;
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
    this.moneyChannelLabel,
    this.referenceType,
    this.referenceId,
    this.referenceCode,
    this.businessTypeId,
    this.businessTypeName,
    this.imagePath,
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

    String asString(dynamic value, {String fallback = ''}) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return fallback;
      return normalized;
    }

    return RevenueDto(
      revenueId: asInt(json['revenueId'] ?? json['id']),
      businessLocationId: asInt(json['businessLocationId']),
      revenueType: referenceCodeFromDynamic(json['revenueType']).trim().isEmpty
          ? asString(json['revenueType'])
          : referenceCodeFromDynamic(json['revenueType']).trim(),
      amount: asDouble(json['amount']),
      revenueDate:
          DateFormatter.parseApiDateTime(asNullableString(json['revenueDate'])) ??
          DateTime.now(),
      documentDate: DateFormatter.parseApiDateTime(
        asNullableString(json['documentDate']),
      ),
      description: asString(json['description']),
      moneyChannel: referenceCodeFromDynamic(
        json['moneyChannel'] ?? json['MoneyChannel'],
      ).isEmpty
          ? null
          : referenceCodeFromDynamic(
              json['moneyChannel'] ?? json['MoneyChannel'],
            ),
      moneyChannelLabel: referenceLabelFromDynamic(
        json['moneyChannel'] ?? json['MoneyChannel'],
      ),
      referenceType: asNullableString(
        json['referenceType'] ??
            json['ReferenceType'] ??
            json['entityType'] ??
            json['EntityType'],
      ),
      referenceId: asNullableInt(
        json['referenceId'] ??
            json['ReferenceId'] ??
            json['entityId'] ??
            json['EntityId'] ??
            json['orderId'] ??
            json['OrderId'] ??
            json['importId'] ??
            json['ImportId'],
      ),
      referenceCode: asNullableString(
        json['referenceCode'] ?? json['ReferenceCode'] ?? json['code'],
      ),
      businessTypeId:
          referenceCodeFromDynamic(json['businessTypeId'] ?? json['BusinessTypeId'])
                  .trim()
                  .isEmpty
              ? asNullableString(json['businessTypeId'] ?? json['BusinessTypeId'])
              : referenceCodeFromDynamic(
                  json['businessTypeId'] ?? json['BusinessTypeId'],
                ).trim(),
      businessTypeName:
          referenceLabelFromDynamic(json['businessTypeId'] ?? json['BusinessTypeId']) ??
          asNullableString(json['businessTypeName'] ?? json['BusinessTypeName']),
      imagePath: asNullableString(
        json['imagePath'] ??
            json['ImagePath'] ??
            json['imageUrl'] ??
            json['receiptImageUrl'] ??
            json['documentUrl'] ??
            json['DocumentUrl'],
      ),
        createdBy: asString(json['createdBy']),
      createdAt:
          DateFormatter.parseApiDateTime(asNullableString(json['createdAt'])) ??
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
      'imagePath': imagePath,
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
    imagePath,
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
