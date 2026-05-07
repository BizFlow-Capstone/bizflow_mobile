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
  final String? moneyChannelLabel;
  final String? referenceType;
  final int? referenceId;
  final String? documentNumber;
  final String? referenceCode;
  final String? revenueCode;
  final String? businessTypeId;
  final String? businessTypeName;
  final String? statusCode;
  final String? statusLabel;
  final String? imagePath;
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
    this.moneyChannelLabel,
    this.referenceType,
    this.referenceId,
    this.documentNumber,
    this.referenceCode,
    this.revenueCode,
    this.businessTypeId,
    this.businessTypeName,
    this.statusCode,
    this.statusLabel,
    this.imagePath,
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
    moneyChannelLabel,
    referenceType,
    referenceId,
    documentNumber,
    referenceCode,
    revenueCode,
    businessTypeId,
    businessTypeName,
    statusCode,
    statusLabel,
    imagePath,
    createdAt,
  ];
}
