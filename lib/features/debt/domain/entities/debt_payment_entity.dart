import '../../../../shared/utils/date_formatter.dart';

class DebtPaymentEntity {
  final int paymentId;
  final double amount;
  final String paymentMethod;
  final String? paymentMethodLabel;
  final String? notes;
  final DateTime? createdAt;
  final String? createdByName;
  final String? action;
  final double? balanceAfter;

  const DebtPaymentEntity({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    this.paymentMethodLabel,
    this.action,
    this.notes,
    this.createdAt,
    this.createdByName,
    this.balanceAfter,
  });

  factory DebtPaymentEntity.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateFormatter.parseApiDateTime(value);
      }
      return null;
    }

    final paymentMethodMap = map['paymentMethod'] is Map ? map['paymentMethod'] : null;

    return DebtPaymentEntity(
      paymentId:
          (map['paymentId'] as num?)?.toInt() ??
          (map['id'] as num?)?.toInt() ??
          (map['transactionId'] as num?)?.toInt() ??
          0,
      amount: toDouble(map['amount']),
      paymentMethod: (paymentMethodMap?['code'] ?? map['paymentMethod'] ?? '').toString(),
      paymentMethodLabel: paymentMethodMap?['label']?.toString(),
      action: (map['debtAction'] ?? map['action'] ?? map['type'])?.toString(),
      notes: map['notes']?.toString(),
      createdAt: toDate(
        map['createdAt'] ?? map['paymentDate'] ?? map['paidAt'],
      ),
      createdByName:
          (map['createdByName'] ?? map['createdBy'] ?? map['createdByUserName'])
              ?.toString(),
      balanceAfter: map['balanceAfter'] == null
          ? null
          : toDouble(map['balanceAfter']),
    );
  }
}
