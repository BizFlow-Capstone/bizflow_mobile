import 'package:drift/drift.dart';

class OrdersTable extends Table {
  TextColumn get id => text()();

  TextColumn get scopeKey => text()();

  TextColumn get orderCode => text().withDefault(const Constant(''))();

  TextColumn get customerName => text().nullable()();

  TextColumn get customerPhone => text().nullable()();

  TextColumn get locationId => text()();

  TextColumn get locationName => text().withDefault(const Constant(''))();

  TextColumn get status => text()();

  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();

  RealColumn get subtotal => real().withDefault(const Constant(0.0))();

  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();

  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();

  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();

  RealColumn get cashAmount => real().withDefault(const Constant(0.0))();

  RealColumn get bankAmount => real().withDefault(const Constant(0.0))();

  RealColumn get debtAmount => real().withDefault(const Constant(0.0))();

  IntColumn get debtorId => integer().nullable()();

  TextColumn get note => text().nullable()();

  IntColumn get createdAtEpoch => integer()();

  IntColumn get updatedAtEpoch => integer()();

  IntColumn get completedAtEpoch => integer().nullable()();

  IntColumn get cancelledAtEpoch => integer().nullable()();

  TextColumn get cancelReason => text().nullable()();

  TextColumn get invoiceNumber => text().nullable()();

  IntColumn get invoicedAtEpoch => integer().nullable()();

  TextColumn get createdByProfileId => text().nullable()();

  TextColumn get createdByProfileFullName => text().nullable()();

  IntColumn get cachedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id, scopeKey};
}
