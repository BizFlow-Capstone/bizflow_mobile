class GeneralLedgerEntryModel {
  final int entryId;
  final String documentNumber;
  final String date;
  final String note;
  final double amount;
  final String transactionType;
  final String transactionCategory;
  final String accountType;
  final String accountCategory;
  final String referenceType;
  final int? referenceId;

  GeneralLedgerEntryModel({
    required this.entryId,
    required this.documentNumber,
    required this.date,
    required this.note,
    required this.amount,
    required this.transactionType,
    required this.transactionCategory,
    required this.accountType,
    required this.accountCategory,
    required this.referenceType,
    this.referenceId,
  });

  factory GeneralLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return GeneralLedgerEntryModel(
      entryId: json['entryId'] as int? ?? 0,
      documentNumber: json['documentNumber'] as String? ?? '',
      date: json['date'] as String? ?? '',
      note: json['note'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: json['transactionType'] as String? ?? '',
      transactionCategory: json['transactionCategory'] as String? ?? '',
      accountType: json['accountType'] as String? ?? '',
      accountCategory: json['accountCategory'] as String? ?? '',
      referenceType: json['referenceType'] as String? ?? '',
      referenceId: json['referenceId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'documentNumber': documentNumber,
      'date': date,
      'note': note,
      'amount': amount,
      'transactionType': transactionType,
      'transactionCategory': transactionCategory,
      'accountType': accountType,
      'accountCategory': accountCategory,
      'referenceType': referenceType,
      'referenceId': referenceId,
    };
  }
}
