import 'package:equatable/equatable.dart';

class CostEntity extends Equatable {
  final int id;
  final int locationId;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final String? paymentMethod;
  final String? documentUrl;
  final String? referenceType;
  final int? referenceId;
  final String? referenceCode;
  final DateTime createdAt;

  const CostEntity({
    required this.id,
    required this.locationId,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.paymentMethod,
    this.documentUrl,
    this.referenceType,
    this.referenceId,
    this.referenceCode,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        locationId,
        type,
        amount,
        date,
        description,
        paymentMethod,
        documentUrl,
        referenceType,
        referenceId,
        referenceCode,
        createdAt,
      ];
}