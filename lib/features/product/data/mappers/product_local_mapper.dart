import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/product_entity.dart';

class ProductLocalMapper {
  static ProductEntity toEntity(ProductsTableData row) {
    return ProductEntity(
      id: row.id,
      name: row.name,
      description: row.description,
      price: row.price,
      quantity: row.quantity,
      imageUrl: row.imageUrl,
      barcode: row.barcode,
      category: row.category,
      costPrice: row.costPrice,
      salePrice: row.salePrice,
      unit: row.unit,
      trackInventory: row.trackInventory,
      isActive: row.isActive,
      createdAt: row.createdAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.createdAtEpoch!),
      locationId: row.locationId,
      businessTypeId: row.businessTypeId,
      manufacturer: row.manufacturer,
      businessLocationName: row.businessLocationName,
      saleItems: _decodeSaleItems(row.saleItemsJson),
    );
  }

  static ProductsTableCompanion toCompanion(
    ProductEntity entity, {
    required String scopeKey,
    required int cachedAtEpoch,
  }) {
    return ProductsTableCompanion.insert(
      id: entity.id,
      scopeKey: scopeKey,
      name: entity.name,
      description: Value(entity.description ?? ''),
      price: Value(entity.price),
      quantity: Value(entity.quantity),
      imageUrl: Value(entity.imageUrl),
      barcode: Value(entity.barcode),
      category: Value(entity.category),
      costPrice: Value(entity.costPrice),
      salePrice: Value(entity.salePrice),
      unit: Value(entity.unit),
      trackInventory: Value(entity.trackInventory),
      isActive: Value(entity.isActive),
      createdAtEpoch: Value(entity.createdAt?.millisecondsSinceEpoch),
      locationId: Value(entity.locationId),
      businessTypeId: Value(entity.businessTypeId),
      manufacturer: Value(entity.manufacturer),
      businessLocationName: Value(entity.businessLocationName),
      saleItemsJson: Value(jsonEncode(entity.saleItems)),
      cachedAtEpoch: cachedAtEpoch,
    );
  }

  static List<Map<String, dynamic>> _decodeSaleItems(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
