import 'package:equatable/equatable.dart';
import '../../../../shared/utils/date_formatter.dart';

class RevenueDto extends Equatable {
  final int revenueId;
  final int businessLocationId;
  final String revenueType;
  final double amount;
  final DateTime revenueDate;
  final String description;
  final String? moneyChannel;
  final String createdBy;
  final DateTime createdAt;

  const RevenueDto({
    required this.revenueId,
    required this.businessLocationId,
    required this.revenueType,
    required this.amount,
    required this.revenueDate,
    required this.description,
    this.moneyChannel,
    required this.createdBy,
    required this.createdAt,
  });

  factory RevenueDto.fromJson(Map<String, dynamic> json) {
    return RevenueDto(
      revenueId: json['revenueId'] as int? ?? 0,
      businessLocationId: json['businessLocationId'] as int? ?? 0,
      revenueType: json['revenueType'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      revenueDate: DateFormatter.parseApiDateTime(json['revenueDate'] as String?) ?? DateTime.now(),
      description: json['description'] as String? ?? '',
      moneyChannel: json['moneyChannel'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateFormatter.parseApiDateTime(json['createdAt'] as String?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenueId': revenueId,
      'businessLocationId': businessLocationId,
      'revenueType': revenueType,
      'amount': amount,
      'revenueDate': revenueDate.toIso8601String(),
      'description': description,
      'moneyChannel': moneyChannel,
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
        description,
        moneyChannel,
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
      items: (data['items'] as List<dynamic>?)
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
