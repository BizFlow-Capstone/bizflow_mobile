import 'package:equatable/equatable.dart';

class RevenueEntity extends Equatable {
  final int id;
  final int locationId;
  final String type;
  final double amount;
  final DateTime date;
  final DateTime? documentDate;
  final String description;
  final String? moneyChannel;
  final String? referenceType;
  final int? referenceId;
  final String? referenceCode;
  final String? businessTypeId;
  final String? businessTypeName;
  final DateTime createdAt;

  const RevenueEntity({
    required this.id,
    required this.locationId,
    required this.type,
    required this.amount,
    required this.date,
    this.documentDate,
    required this.description,
    this.moneyChannel,
    this.referenceType,
    this.referenceId,
    this.referenceCode,
    this.businessTypeId,
    this.businessTypeName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    locationId,
    type,
    amount,
    date,
    documentDate,
    description,
    moneyChannel,
    referenceType,
    referenceId,
    referenceCode,
    businessTypeId,
    businessTypeName,
    createdAt,
  ];
}
