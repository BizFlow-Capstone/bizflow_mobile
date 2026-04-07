class DashboardSummaryDto {
  final int? businessLocationId;
  final int includedLocationCount;
  final String fromDate;
  final String toDate;
  final double totalRevenue;
  final double totalCost;
  final int totalCompletedOrders;
  final double totalOutstandingDebt;
  final String? outstandingDebtAsOfUtc;

  const DashboardSummaryDto({
    required this.businessLocationId,
    required this.includedLocationCount,
    required this.fromDate,
    required this.toDate,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalCompletedOrders,
    required this.totalOutstandingDebt,
    required this.outstandingDebtAsOfUtc,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryDto(
      businessLocationId: _parseInt(json['businessLocationId']),
      includedLocationCount: _parseInt(json['includedLocationCount']) ?? 0,
      fromDate: (json['fromDate'] ?? '').toString(),
      toDate: (json['toDate'] ?? '').toString(),
      totalRevenue: _parseDouble(json['totalRevenue']) ?? 0,
      totalCost: _parseDouble(json['totalCost']) ?? 0,
      totalCompletedOrders: _parseInt(json['totalCompletedOrders']) ?? 0,
      totalOutstandingDebt: _parseDouble(json['totalOutstandingDebt']) ?? 0,
      outstandingDebtAsOfUtc: json['outstandingDebtAsOfUtc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessLocationId': businessLocationId,
      'includedLocationCount': includedLocationCount,
      'fromDate': fromDate,
      'toDate': toDate,
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'totalCompletedOrders': totalCompletedOrders,
      'totalOutstandingDebt': totalOutstandingDebt,
      'outstandingDebtAsOfUtc': outstandingDebtAsOfUtc,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
