import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';

class OrderLocalMapper {
  const OrderLocalMapper._();

  static OrderEntity toEntity(OrdersTableData row) {
    return OrderEntity(
      id: row.id,
      orderCode: row.orderCode,
      customerName: row.customerName,
      customerPhone: row.customerPhone,
      locationId: row.locationId,
      locationName: row.locationName,
      status: row.status,
      items: _decodeItems(row.itemsJson),
      subtotal: row.subtotal,
      discountAmount: row.discountAmount,
      taxAmount: row.taxAmount,
      totalAmount: row.totalAmount,
      cashAmount: row.cashAmount,
      bankAmount: row.bankAmount,
      debtAmount: row.debtAmount,
      debtorId: row.debtorId,
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtEpoch),
      completedAt: row.completedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.completedAtEpoch!),
      cancelledAt: row.cancelledAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.cancelledAtEpoch!),
      cancelReason: row.cancelReason,
      invoiceNumber: row.invoiceNumber,
      invoicedAt: row.invoicedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.invoicedAtEpoch!),
    );
  }

  static OrdersTableCompanion toCompanion(
    OrderEntity entity, {
    required String scopeKey,
    required int cachedAtEpoch,
  }) {
    return OrdersTableCompanion.insert(
      id: entity.id,
      scopeKey: scopeKey,
      orderCode: Value(entity.orderCode),
      customerName: Value(entity.customerName),
      customerPhone: Value(entity.customerPhone),
      locationId: entity.locationId,
      locationName: Value(entity.locationName),
      status: entity.status,
      itemsJson: Value(jsonEncode(entity.items.map(_itemToJson).toList())),
      subtotal: Value(entity.subtotal),
      discountAmount: Value(entity.discountAmount),
      taxAmount: Value(entity.taxAmount),
      totalAmount: Value(entity.totalAmount),
      cashAmount: Value(entity.cashAmount),
      bankAmount: Value(entity.bankAmount),
      debtAmount: Value(entity.debtAmount),
      debtorId: Value(entity.debtorId),
      note: Value(entity.note),
      createdAtEpoch: entity.createdAt.millisecondsSinceEpoch,
      updatedAtEpoch: entity.updatedAt.millisecondsSinceEpoch,
      completedAtEpoch: Value(entity.completedAt?.millisecondsSinceEpoch),
      cancelledAtEpoch: Value(entity.cancelledAt?.millisecondsSinceEpoch),
      cancelReason: Value(entity.cancelReason),
      invoiceNumber: Value(entity.invoiceNumber),
      invoicedAtEpoch: Value(entity.invoicedAt?.millisecondsSinceEpoch),
      cachedAtEpoch: cachedAtEpoch,
    );
  }

  static Map<String, dynamic> _itemToJson(OrderItemEntity item) {
    return {
      'id': item.id,
      'productId': item.productId,
      'saleItemId': item.saleItemId,
      'unitName': item.unitName,
      'productName': item.productName,
      'price': item.price,
      'quantity': item.quantity,
      'discount': item.discount,
      'note': item.note,
    };
  }

  static List<OrderItemEntity> _decodeItems(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map>()
          .map(
            (item) => OrderItemEntity(
              id: item['id']?.toString(),
              productId: item['productId']?.toString() ?? '',
              saleItemId: item['saleItemId'] as int?,
              unitName: item['unitName']?.toString(),
              productName: item['productName']?.toString() ?? '',
              price: (item['price'] as num?)?.toDouble() ?? 0,
              quantity: (item['quantity'] as num?)?.toDouble() ?? 0,
              discount: (item['discount'] as num?)?.toDouble() ?? 0,
              note: item['note']?.toString(),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
