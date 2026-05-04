import "../../../../shared/cache/cache_manager.dart";
import 'package:flutter/foundation.dart';

import '../domain/entities/debt_payment_entity.dart';
import '../domain/entities/debtor_entity.dart';
import 'debtor_api_service.dart';
import 'models/debtor_models.dart';

class DebtorRepository {
  final DebtorApiService _service;

  DebtorRepository({required DebtorApiService service}) : _service = service;

  Future<DebtorListResult> getDebtors({
    List<int>? businessLocationIds,
    String? search,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _service.getDebtors(
        businessLocationIds: businessLocationIds,
        search: search,
        isActive: isActive,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return DebtorListResult.fromApi(response);
    } catch (e) {
      debugPrint('DebtorRepository.getDebtors error: $e');
      rethrow;
    }
  }

  Future<DebtorEntity?> getDebtorDetail(int debtorId) async {
    try {
      final response = await _service.getDebtorDetail(debtorId);
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return DebtorEntity.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('DebtorRepository.getDebtorDetail error: $e');
      rethrow;
    }
  }

  Future<void> getDebtorDetailSWR({
    required int debtorId,
    required void Function(DebtorEntity? detail, bool isFromCache) onData,
    void Function(dynamic error)? onError,
  }) async {
    final cacheKey = 'cache_debtor_detail_$debtorId';
    await CacheManager().fetchWithSWR<DebtorEntity?>(
      key: cacheKey,
      fetcher: ({cancelToken}) => getDebtorDetail(debtorId),
      fromJson: (json) {
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          return DebtorEntity.fromMap(data);
        }
        return null;
      },
      toJson: (detail) {
        return {'data': detail?.toMap()};
      },
      onData: onData,
      onError: onError,
    );
  }

  Future<DebtorEntity?> createDebtor({
    required int businessLocationId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    double? creditLimit,
  }) async {
    try {
      final response = await _service.createDebtor(
        businessLocationId: businessLocationId,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        creditLimit: creditLimit,
      );
      await clearCache();

      final payload = _extractDataMap(response);
      if (payload == null) return null;
      return DebtorEntity.fromMap(payload);
    } catch (e) {
      debugPrint('DebtorRepository.createDebtor error: $e');
      rethrow;
    }
  }

  Future<DebtorEntity?> updateDebtor({
    required int debtorId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    double? creditLimit,
  }) async {
    try {
      final response = await _service.updateDebtor(
        debtorId: debtorId,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        creditLimit: creditLimit,
      );
      await clearCache();

      final payload = _extractDataMap(response);
      if (payload == null) return null;
      return DebtorEntity.fromMap(payload);
    } catch (e) {
      debugPrint('DebtorRepository.updateDebtor error: $e');
      rethrow;
    }
  }

  Future<void> recordDebtAdjustment({
    required int debtorId,
    required double amount,
    required String action,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      await _service.recordDebtAdjustment(
        debtorId: debtorId,
        amount: amount,
        action: action,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await clearCache();
    } catch (e) {
      debugPrint('DebtorRepository.recordDebtAdjustment error: $e');
      rethrow;
    }
  }

  Future<List<DebtPaymentEntity>> getDebtPaymentHistory(int debtorId) async {
    try {
      final response = await _service.getDebtPaymentHistory(debtorId);
      final rootData = response['data'];

      dynamic itemsRaw;
      if (rootData is Map<String, dynamic>) {
        itemsRaw = rootData['items'] ?? rootData['payments'];
      } else {
        itemsRaw = rootData;
      }

      if (itemsRaw is! List) return <DebtPaymentEntity>[];

      return itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(DebtPaymentEntity.fromMap)
          .toList();
    } catch (e) {
      debugPrint('DebtorRepository.getDebtPaymentHistory error: $e');
      rethrow;
    }
  }

  Future<void> getDebtPaymentHistorySWR({
    required int debtorId,
    required void Function(List<DebtPaymentEntity> items, bool isFromCache)
    onData,
    void Function(dynamic error)? onError,
  }) async {
    final cacheKey = 'cache_debtor_payment_history_$debtorId';
    await CacheManager().fetchWithSWR<List<DebtPaymentEntity>>(
      key: cacheKey,
      fetcher: ({cancelToken}) => getDebtPaymentHistory(debtorId),
      fromJson: (json) {
        final rawItems = json['items'];
        if (rawItems is! List) {
          return <DebtPaymentEntity>[];
        }
        return rawItems
            .whereType<Map<String, dynamic>>()
            .map(DebtPaymentEntity.fromMap)
            .toList();
      },
      toJson: (items) {
        return {
          'items': items
              .map(
                (item) => {
                  'paymentId': item.paymentId,
                  'amount': item.amount,
                  'paymentMethod': item.paymentMethod,
                  'paymentMethodLabel': item.paymentMethodLabel,
                  'action': item.action,
                  'notes': item.notes,
                  'createdAt': item.createdAt?.toIso8601String(),
                  'createdByName': item.createdByName,
                  'balanceAfter': item.balanceAfter,
                },
              )
              .toList(),
        };
      },
      onData: onData,
      onError: onError,
    );
  }

  Future<List<DebtorEntity>> getActiveDebtorsByLocation(int locationId) async {
    try {
      final response = await _service.getActiveDebtorsByLocation(locationId);
      // Response shape: { "data": [ ...debtors ] } or { "data": { "items": [...] } }
      final raw = response['data'];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(DebtorEntity.fromMap)
            .toList();
      }
      if (raw is Map<String, dynamic>) {
        final items = raw['items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(DebtorEntity.fromMap)
              .toList();
        }
      }
      return <DebtorEntity>[];
    } catch (e) {
      debugPrint('DebtorRepository.getActiveDebtorsByLocation error: $e');
      rethrow;
    }
  }

  Future<void> updateDebtorStatus({
    required int debtorId,
    required bool isActive,
  }) async {
    try {
      await _service.updateDebtorStatus(debtorId: debtorId, isActive: isActive);
      await clearCache();
    } catch (e) {
      debugPrint('DebtorRepository.updateDebtorStatus error: $e');
      rethrow;
    }
  }

  Future<void> deleteDebtor({required int debtorId, bool force = false}) async {
    try {
      await _service.deleteDebtor(debtorId: debtorId, force: force);
      await clearCache();
      await clearCache();
    } catch (e) {
      debugPrint('DebtorRepository.deleteDebtor error: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _extractDataMap(Map<String, dynamic> response) {
    final root = response['data'];
    if (root is Map<String, dynamic>) {
      if (root['debtor'] is Map<String, dynamic>) {
        return root['debtor'] as Map<String, dynamic>;
      }
      return root;
    }
    return null;
  }

  Future<void> clearCache() async {
    await CacheManager().removeByPrefix("cache_debtors_");
    await CacheManager().removeByPrefix("cache_debtor_detail_");
    await CacheManager().removeByPrefix("cache_debtor_payment_history_");
    await CacheManager().removeByPrefix("cache_debtors_active_location_");
  }
}
