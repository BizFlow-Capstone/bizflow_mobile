class GlEntryModel {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final String channel;

  const GlEntryModel({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.channel,
  });
}

class AccountingItemModel {
  final String code;
  DateTime date;
  String description;
  double amount;
  final String type;

  AccountingItemModel({
    required this.code,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
  });
}

class BookItemModel {
  final String code;
  final String name;
  final String group;

  const BookItemModel({
    required this.code,
    required this.name,
    required this.group,
  });
}

class TaxPaymentItemModel {
  final String taxType;
  double amount;
  DateTime date;
  String reference;

  TaxPaymentItemModel({
    required this.taxType,
    required this.amount,
    required this.date,
    required this.reference,
  });
}
