import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/import_model.dart';

class ImportLocalMapper {
  const ImportLocalMapper._();

  static ImportHistoryItemModel toHistoryItem(ImportsTableData row) {
    return ImportHistoryItemModel(
      importId: row.id,
      importCode: row.importCode,
      importType: row.importType,
      status: row.status,
      businessLocationId: row.businessLocationId,
      businessLocationName: row.businessLocationName,
      supplier: row.supplier,
      note: row.note,
      receivedAt: row.receivedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.receivedAtEpoch!),
      totalAmount: row.totalAmount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtEpoch),
      updatedAt: row.updatedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.updatedAtEpoch!),
      imageUrl: row.imageUrl,
    );
  }

  static ImportDetailModel toDetailModel(ImportsTableData row) {
    return ImportDetailModel(
      importId: row.id,
      importCode: row.importCode,
      importType: row.importType,
      status: row.status,
      businessLocationId: row.businessLocationId,
      businessLocationName: row.businessLocationName,
      supplier: row.supplier,
      note: row.note,
      receivedAt: row.receivedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.receivedAtEpoch!),
      totalAmount: row.totalAmount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtEpoch),
      updatedAt: row.updatedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.updatedAtEpoch!),
      imageUrl: row.imageUrl,
      items: _decodeItems(row.itemsJson),
    );
  }

  static ImportsTableCompanion toCompanion(
    ImportHistoryItemModel model, {
    required String scopeKey,
    required int cachedAtEpoch,
    List<ImportItemModel> items = const [],
  }) {
    return ImportsTableCompanion.insert(
      id: model.importId,
      scopeKey: scopeKey,
      importCode: Value(model.importCode),
      importType: Value(model.importType),
      status: Value(model.status),
      businessLocationId: model.businessLocationId,
      businessLocationName: Value(model.businessLocationName),
      supplier: Value(model.supplier),
      note: Value(model.note),
      receivedAtEpoch: Value(model.receivedAt?.millisecondsSinceEpoch),
      totalAmount: Value(model.totalAmount),
      createdAtEpoch: model.createdAt.millisecondsSinceEpoch,
      updatedAtEpoch: Value(model.updatedAt?.millisecondsSinceEpoch),
      imageUrl: Value(model.imageUrl),
      itemsJson: Value(jsonEncode(items.map((item) => item.toJson()).toList())),
      cachedAtEpoch: cachedAtEpoch,
    );
  }

  static List<ImportItemModel> _decodeItems(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map>()
          .map(
            (item) => ImportItemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
