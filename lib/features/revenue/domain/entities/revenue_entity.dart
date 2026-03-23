import 'package:equatable/equatable.dart';

class RevenueEntity extends Equatable {
  final int id;
  final int locationId;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final String? moneyChannel;
  final DateTime createdAt;

  const RevenueEntity({
    required this.id,
    required this.locationId,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.moneyChannel,
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
        moneyChannel,
        createdAt,
      ];
}
