import 'package:equatable/equatable.dart';

abstract class DebtorEvent extends Equatable {
  const DebtorEvent();

  @override
  List<Object?> get props => [];
}

class LoadDebtorsRequested extends DebtorEvent {
  final List<int>? businessLocationIds;
  final String? search;
  final bool? isActive;
  final int pageNumber;
  final int pageSize;

  const LoadDebtorsRequested({
    this.businessLocationIds,
    this.search,
    this.isActive,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [
    businessLocationIds,
    search,
    isActive,
    pageNumber,
    pageSize,
  ];
}

class RefreshDebtorsRequested extends DebtorEvent {
  const RefreshDebtorsRequested();
}

class ToggleDebtorStatusRequested extends DebtorEvent {
  final int debtorId;
  final bool isActive;

  const ToggleDebtorStatusRequested({
    required this.debtorId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [debtorId, isActive];
}

class DeleteDebtorRequested extends DebtorEvent {
  final int debtorId;
  final bool force;

  const DeleteDebtorRequested({required this.debtorId, this.force = false});

  @override
  List<Object?> get props => [debtorId, force];
}

class LoadActiveDebtorsByLocationRequested extends DebtorEvent {
  final int locationId;

  const LoadActiveDebtorsByLocationRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class CreateDebtorRequested extends DebtorEvent {
  final int businessLocationId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final double? creditLimit;

  const CreateDebtorRequested({
    required this.businessLocationId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.creditLimit,
  });

  @override
  List<Object?> get props => [
    businessLocationId,
    name,
    phone,
    address,
    notes,
    creditLimit,
  ];
}

class UpdateDebtorRequested extends DebtorEvent {
  final int debtorId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final double? creditLimit;

  const UpdateDebtorRequested({
    required this.debtorId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.creditLimit,
  });

  @override
  List<Object?> get props => [
    debtorId,
    name,
    phone,
    address,
    notes,
    creditLimit,
  ];
}

class RecordDebtAdjustmentRequested extends DebtorEvent {
  final int debtorId;
  final double amount;
  final String paymentMethod;
  final String? notes;

  const RecordDebtAdjustmentRequested({
    required this.debtorId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
  });

  @override
  List<Object?> get props => [debtorId, amount, paymentMethod, notes];
}

class LoadDebtorDetailRequested extends DebtorEvent {
  final int debtorId;

  const LoadDebtorDetailRequested({required this.debtorId});

  @override
  List<Object?> get props => [debtorId];
}

class LoadDebtPaymentHistoryRequested extends DebtorEvent {
  final int debtorId;

  const LoadDebtPaymentHistoryRequested({required this.debtorId});

  @override
  List<Object?> get props => [debtorId];
}
