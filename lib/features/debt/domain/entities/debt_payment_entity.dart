import '../../../../shared/utils/date_formatter.dart';

class DebtPaymentEntity {
  final int paymentId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime? createdAt;
  final String? createdByName;
  final double? balanceAfter;

  const DebtPaymentEntity({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
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

    return DebtPaymentEntity(
      paymentId:
          (map['paymentId'] as num?)?.toInt() ??
          (map['id'] as num?)?.toInt() ??
          0,
      amount: toDouble(map['amount']),
      paymentMethod: (map['paymentMethod'] ?? '').toString(),
      notes: map['notes']?.toString(),
      createdAt: toDate(map['createdAt'] ?? map['paymentDate']),
      createdByName:
          (map['createdByName'] ?? map['createdBy'] ?? map['createdByUserName'])
              ?.toString(),
      balanceAfter: map['balanceAfter'] == null
          ? null
          : toDouble(map['balanceAfter']),
    );
  }
}
