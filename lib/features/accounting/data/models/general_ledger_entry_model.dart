import '../../../../core/reference/data/reference_item.dart';

class GeneralLedgerEntryModel {
  final int entryId;
  final String documentNumber;
  final String? documentDate;
  final String date;
  final String note;
  final double amount;
  final String transactionType;
  final String? transactionTypeLabel;
  final String transactionCategory;
  final String accountType;
  final String accountCategory;
  final String? moneyChannel;
  final String? moneyChannelLabel;
  final String? effectiveStatus;
  final String referenceType;
  final String? referenceTypeLabel;
  final int? referenceId;
  final String? entityType;
  final int? entityId;
  final String? createdAt;

  GeneralLedgerEntryModel({
    required this.entryId,
    required this.documentNumber,
    this.documentDate,
    required this.date,
    required this.note,
    required this.amount,
    required this.transactionType,
    this.transactionTypeLabel,
    required this.transactionCategory,
    required this.accountType,
    required this.accountCategory,
    this.moneyChannel,
    this.moneyChannelLabel,
    this.effectiveStatus,
    required this.referenceType,
    this.referenceTypeLabel,
    this.referenceId,
    this.entityType,
    this.entityId,
    this.createdAt,
  });

  factory GeneralLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    String asString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      final text = value.toString();
      return text;
    }

    final source = json['source'] is Map<String, dynamic>
        ? json['source'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final debitAmount = asDouble(json['debitAmount']);
    final creditAmount = asDouble(json['creditAmount']);
    final normalizedAmount = debitAmount != 0 || creditAmount != 0
        ? (debitAmount - creditAmount)
        : asDouble(json['amount']);

    final rawTransactionType = json['transactionType'];
    final rawMoneyChannel = json['moneyChannel'];
    final rawReferenceType = source['referenceType'] ?? json['referenceType'];
    final refType = referenceCodeFromDynamic(rawReferenceType);
    final refId = asNullableInt(source['referenceId'] ?? json['referenceId']);
    final entityType = asString(source['entityType'], fallback: '');
    final entityId = asNullableInt(source['entityId']);

    final fallbackDocument = refType.isNotEmpty && refId != null
        ? '${refType.toUpperCase()}-$refId'
        : (entityType.isNotEmpty && entityId != null
              ? '${entityType.toUpperCase()}-$entityId'
              : 'GL-${asInt(json['entryId'])}');

    return GeneralLedgerEntryModel(
      entryId: asInt(json['entryId']),
      documentNumber: asString(
        json['documentNumber'] ?? source['referenceCode'],
        fallback: fallbackDocument,
      ),
      documentDate:
          asString(
            json['documentDate'] ?? source['documentDate'],
          ).trim().isEmpty
          ? null
          : asString(json['documentDate'] ?? source['documentDate']).trim(),
      date: asString(json['date'] ?? json['entryDate'] ?? json['createdAt']),
      note: asString(json['note'] ?? json['description']),
      amount: normalizedAmount,
        transactionType: referenceCodeFromDynamic(rawTransactionType),
        transactionTypeLabel: referenceLabelFromDynamic(rawTransactionType),
      transactionCategory: asString(json['transactionCategory']),
      accountType: asString(json['accountType']),
      accountCategory: asString(json['accountCategory']),
        moneyChannel: referenceCodeFromDynamic(rawMoneyChannel).trim().isEmpty
          ? null
          : referenceCodeFromDynamic(rawMoneyChannel).trim(),
        moneyChannelLabel: referenceLabelFromDynamic(rawMoneyChannel),
      effectiveStatus: asString(json['effectiveStatus']).trim().isEmpty
          ? null
          : asString(json['effectiveStatus']).trim(),
      referenceType: refType,
        referenceTypeLabel: referenceLabelFromDynamic(rawReferenceType),
      referenceId: refId,
      entityType: entityType.trim().isEmpty ? null : entityType.trim(),
      entityId: entityId,
      createdAt:
          asString(json['createdAt'] ?? source['createdAt']).trim().isEmpty
          ? null
          : asString(json['createdAt'] ?? source['createdAt']).trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'documentNumber': documentNumber,
      'documentDate': documentDate,
      'date': date,
      'note': note,
      'amount': amount,
      'transactionType': transactionType,
      'transactionTypeLabel': transactionTypeLabel,
      'transactionCategory': transactionCategory,
      'accountType': accountType,
      'accountCategory': accountCategory,
      'moneyChannel': moneyChannel,
      'moneyChannelLabel': moneyChannelLabel,
      'effectiveStatus': effectiveStatus,
      'referenceType': referenceType,
      'referenceTypeLabel': referenceTypeLabel,
      'referenceId': referenceId,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': createdAt,
    };
  }
}
