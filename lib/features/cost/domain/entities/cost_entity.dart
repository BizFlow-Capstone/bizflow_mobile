import 'package:equatable/equatable.dart';

class CostEntity extends Equatable {
  final int id;
  final int locationId;
  final String type;
  final double amount;
  final DateTime date;
  final DateTime? documentDate;
  final String description;
  final String? paymentMethod;
  final String? documentUrl;
  final String? referenceType;
  final int? referenceId;
  final String? documentNumber;
  final String? referenceCode;
  final String? statusCode;
  final String? statusLabel;
  final String? imagePath;
  final DateTime createdAt;

  const CostEntity({
    required this.id,
    required this.locationId,
    required this.type,
    required this.amount,
    required this.date,
    this.documentDate,
    required this.description,
    this.paymentMethod,
    this.documentUrl,
    this.referenceType,
    this.referenceId,
    this.documentNumber,
    this.referenceCode,
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
    paymentMethod,
    documentUrl,
    referenceType,
    referenceId,
    documentNumber,
    referenceCode,
    statusCode,
    statusLabel,
    imagePath,
    createdAt,
  ];
}
