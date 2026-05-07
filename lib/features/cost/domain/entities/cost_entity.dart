import 'package:equatable/equatable.dart';

class CostEntity extends Equatable {
  final int id;
  final int locationId;
  final String type;
  final String? costType;
  final String? costTypeLabel;
  final double amount;
  final DateTime date;
  final DateTime? documentDate;
  final String description;
  final String? paymentMethod;
  final String? paymentMethodLabel;
  final String? documentUrl;
  final String? referenceType;
  final int? referenceId;
  final String? documentNumber;
  final String? referenceCode;
  final String? costCode;
  final String? statusCode;
  final String? statusLabel;
  final String? imagePath;
  final DateTime createdAt;

  const CostEntity({
    required this.id,
    required this.locationId,
    required this.type,
    this.costType,
    this.costTypeLabel,
    required this.amount,
    required this.date,
    this.documentDate,
    required this.description,
    this.paymentMethod,
    this.paymentMethodLabel,
    this.documentUrl,
    this.referenceType,
    this.referenceId,
    this.documentNumber,
    this.referenceCode,
    this.costCode,
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
    costType,
    costTypeLabel,
    amount,
    date,
    documentDate,
    description,
    paymentMethod,
    paymentMethodLabel,
    documentUrl,
    referenceType,
    referenceId,
    documentNumber,
    referenceCode,
    costCode,
    statusCode,
    statusLabel,
    imagePath,
    createdAt,
    costType,
    costTypeLabel,
  ];
}
