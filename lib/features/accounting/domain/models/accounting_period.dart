import '../../../../shared/utils/date_formatter.dart';
import '../../../../core/reference/data/reference_item.dart';

class AccountingPeriod {
  final int periodId;
  final int businessLocationId;
  final String periodType; // quarter | year | custom
  final int year;
  final int? quarter;
  final String startDate; // ISO date string YYYY-MM-DD
  final String endDate;
  final double? openingCashBalance;
  final double? openingBankBalance;
  final String status; // open | finalized | reopened
  final String? statusLabel; // Display label for status
  final DateTime? finalizedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AccountingPeriod({
    required this.periodId,
    required this.businessLocationId,
    required this.periodType,
    required this.year,
    this.quarter,
    required this.startDate,
    required this.endDate,
    this.openingCashBalance,
    this.openingBankBalance,
    required this.status,
    this.statusLabel,
    this.finalizedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory AccountingPeriod.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String asString(dynamic value, {String fallback = ''}) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return fallback;
      return normalized;
    }

    double? asNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    String normalizePeriodStatus(String statusCode) {
      final normalized = statusCode.trim().toLowerCase();
      if (normalized.contains('reopen')) return 'reopened';
      if (normalized.contains('final') ||
          normalized.contains('close') ||
          normalized.contains('lock')) {
        return 'finalized';
      }
      return 'open';
    }

    String normalizePeriodType(String periodTypeCode) {
      final normalized = periodTypeCode.trim().toLowerCase();
      if (normalized.contains('quarter') || normalized == 'q') return 'quarter';
      if (normalized.contains('year')) return 'year';
      if (normalized.contains('custom')) return 'custom';
      return normalized.isEmpty ? 'quarter' : normalized;
    }

    final rawStatus = json['status'];
    final statusCode = referenceCodeFromDynamic(rawStatus);
    final rawPeriodType = json['periodType'];
    final periodTypeCode = referenceCodeFromDynamic(rawPeriodType);
    return AccountingPeriod(
      periodId: asInt(json['periodId']),
      businessLocationId: asInt(json['businessLocationId']),
      periodType: normalizePeriodType(
        periodTypeCode.isEmpty
            ? asString(rawPeriodType, fallback: 'quarter')
            : periodTypeCode,
      ),
      year: asInt(json['year'], fallback: DateTime.now().year),
      quarter: json['quarter'] is num
          ? (json['quarter'] as num).toInt()
          : int.tryParse(asString(json['quarter'])),
      startDate: asString(json['startDate']),
      endDate: asString(json['endDate']),
      openingCashBalance: asNullableDouble(json['openingCashBalance']),
      openingBankBalance: asNullableDouble(json['openingBankBalance']),
      status: normalizePeriodStatus(statusCode),
      statusLabel: referenceLabelFromDynamic(rawStatus),
        finalizedAt: DateFormatter.parseApiDateTime(asString(json['finalizedAt'])),
        createdAt: DateFormatter.parseApiDateTime(
          asString(json['createdAt']),
          fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
        updatedAt: DateFormatter.parseApiDateTime(asString(json['updatedAt'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'periodId': periodId,
        'businessLocationId': businessLocationId,
        'periodType': periodType,
        'year': year,
        'quarter': quarter,
        'startDate': startDate,
        'endDate': endDate,
        'openingCashBalance': openingCashBalance,
        'openingBankBalance': openingBankBalance,
        'status': status,
        'finalizedAt': finalizedAt != null
          ? DateFormatter.toApiUtcIsoString(finalizedAt!)
          : null,
        'createdAt': DateFormatter.toApiUtcIsoString(createdAt),
        'updatedAt': updatedAt != null
          ? DateFormatter.toApiUtcIsoString(updatedAt!)
          : null,
      };

  /// Display label: Q1/2026 hoặc 2026 hoặc 01/01 - 28/02/2026
  String get displayLabel {
    if (periodType == 'quarter' && quarter != null) {
      return 'Q$quarter/$year';
    } else if (periodType == 'year') {
      return '$year';
    } else {
      // custom
      return '$startDate – $endDate';
    }
  }

  bool get isOpen => status == 'open' || status == 'reopened';
  bool get isFinalized => status == 'finalized';
  bool get isReopened => status == 'reopened';
}

class AccountingPeriodAuditLog {
  final int logId;
  final int periodId;
  final String action;
  final dynamic oldValue;
  final dynamic newValue;
  final String? reason;
  final DateTime createdAt;

  const AccountingPeriodAuditLog({
    required this.logId,
    required this.periodId,
    required this.action,
    this.oldValue,
    this.newValue,
    this.reason,
    required this.createdAt,
  });

  factory AccountingPeriodAuditLog.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String asString(dynamic value, {String fallback = ''}) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return fallback;
      return normalized;
    }

    String? asNullableString(dynamic value) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return null;
      return normalized;
    }

    return AccountingPeriodAuditLog(
      logId: asInt(json['logId']),
      periodId: asInt(json['periodId']),
      action: referenceCodeFromDynamic(json['action']).trim().isEmpty
          ? asString(json['action'])
          : referenceCodeFromDynamic(json['action']).trim(),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      reason: asNullableString(json['reason']),
      createdAt: DateFormatter.parseApiDateTime(
            asString(json['createdAt']),
            fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
    );
  }
}

class OpeningBalanceSuggestion {
  final bool hasSuggestion;
  final String? suggestionReasonCode;
  final String? suggestionReason;
  final double? openingCashBalance;
  final double? openingBankBalance;
  final int? sourcePeriodId;

  const OpeningBalanceSuggestion({
    required this.hasSuggestion,
    this.suggestionReasonCode,
    this.suggestionReason,
    this.openingCashBalance,
    this.openingBankBalance,
    this.sourcePeriodId,
  });

  factory OpeningBalanceSuggestion.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double? asNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    String? asNullableString(dynamic value) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return null;
      return normalized;
    }

    return OpeningBalanceSuggestion(
      hasSuggestion: json['hasSuggestion'] as bool? ?? false,
      suggestionReasonCode: asNullableString(json['suggestionReasonCode']),
      suggestionReason: asNullableString(json['suggestionReason']),
      openingCashBalance: asNullableDouble(json['openingCashBalance']),
      openingBankBalance: asNullableDouble(json['openingBankBalance']),
      sourcePeriodId: asNullableInt(json['sourcePeriodId']),
    );
  }
}
