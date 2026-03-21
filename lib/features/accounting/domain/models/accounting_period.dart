import '../../../../shared/utils/date_formatter.dart';

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
    this.finalizedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory AccountingPeriod.fromJson(Map<String, dynamic> json) {
    return AccountingPeriod(
      periodId: json['periodId'] as int? ?? 0,
      businessLocationId: json['businessLocationId'] as int? ?? 0,
      periodType: json['periodType'] as String? ?? 'quarter',
      year: json['year'] as int? ?? DateTime.now().year,
      quarter: json['quarter'] as int?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      openingCashBalance: (json['openingCashBalance'] as num?)?.toDouble(),
      openingBankBalance: (json['openingBankBalance'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'open',
        finalizedAt: DateFormatter.parseApiDateTime(json['finalizedAt'] as String?),
        createdAt: DateFormatter.parseApiDateTime(
          json['createdAt'] as String?,
          fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
        updatedAt: DateFormatter.parseApiDateTime(json['updatedAt'] as String?),
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
    return AccountingPeriodAuditLog(
      logId: json['logId'] as int? ?? 0,
      periodId: json['periodId'] as int? ?? 0,
      action: json['action'] as String? ?? '',
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      reason: json['reason'] as String?,
      createdAt: DateFormatter.parseApiDateTime(
            json['createdAt'] as String?,
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
    return OpeningBalanceSuggestion(
      hasSuggestion: json['hasSuggestion'] as bool? ?? false,
      suggestionReasonCode: json['suggestionReasonCode'] as String?,
      suggestionReason: json['suggestionReason'] as String?,
      openingCashBalance:
          (json['openingCashBalance'] as num?)?.toDouble(),
      openingBankBalance:
          (json['openingBankBalance'] as num?)?.toDouble(),
      sourcePeriodId: json['sourcePeriodId'] as int?,
    );
  }
}
