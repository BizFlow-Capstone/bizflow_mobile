import 'dart:io';

import 'datasources/import_local_datasource.dart';
import 'import_api_service.dart';
import 'models/import_model.dart';
import '../../../shared/cache/local_api_cache_store.dart';
import '../../../shared/models/ocr_purchase_invoice_dto.dart';

class ImportRepository {
  final ImportApiService _apiService;
  final LocalApiCacheStore _localApiCache;
  final ImportLocalDataSource _localDataSource;

  ImportRepository(
    this._apiService, {
    LocalApiCacheStore? localApiCacheStore,
    ImportLocalDataSource? localDataSource,
  }) : _localApiCache = localApiCacheStore ?? LocalApiCacheStore(),
       _localDataSource = localDataSource ?? ImportLocalDataSource();

  int? _parseImportId(Map<String, dynamic>? payload) {
    if (payload == null) return null;

    final raw = payload['importId'] ?? payload['ImportId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<Map<String, dynamic>?> _tryGetFreshImportDetail(int? importId) async {
    if (importId == null || importId <= 0) return null;

    try {
      final detail = await _apiService.getImportDetail(importId);
      await _localDataSource.upsertDetail(ImportDetailModel.fromJson(detail));
      await _localApiCache.setMap(
        'import_detail_$importId',
        detail,
        groupKey: 'imports',
        cacheType: 'detail',
      );
      return detail;
    } catch (_) {
      return null;
    }
  }

  String _importsCacheKey({
    String? status,
    String? importType,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    int? pageNumber,
    int? pageSize,
  }) {
    return 'imports_${businessLocationId ?? 'all'}_${status ?? 'all'}_${importType ?? 'all'}_${fromDate?.toIso8601String() ?? 'none'}_${toDate?.toIso8601String() ?? 'none'}_p${pageNumber ?? 1}_s${pageSize ?? 10}';
  }

  String _importsScopeKey({
    String? status,
    String? importType,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return 'imports_${businessLocationId ?? 'all'}_${status ?? 'all'}_${importType ?? 'all'}_${fromDate?.toIso8601String() ?? 'none'}_${toDate?.toIso8601String() ?? 'none'}';
  }

  Future<Map<String, dynamic>> getImports({
    String? status,
    String? importType,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    final key = _importsCacheKey(
      status: status,
      importType: importType,
      businessLocationId: businessLocationId,
      fromDate: fromDate,
      toDate: toDate,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    final scopeKey = _importsScopeKey(
      status: status,
      importType: importType,
      businessLocationId: businessLocationId,
      fromDate: fromDate,
      toDate: toDate,
    );

    try {
      final data = await _apiService.getImports(
        status: status,
        importType: importType,
        businessLocationId: businessLocationId,
        fromDate: fromDate,
        toDate: toDate,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      await _localApiCache.setMap(
        key,
        data,
        groupKey: 'imports',
        cacheType: 'list',
      );

      final items = (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ImportHistoryItemModel.fromJson)
          .toList();
      await _localDataSource.replaceForScope(scopeKey, items);
      return data;
    } catch (e) {
      final localItems = await _localDataSource.getByScopeKey(scopeKey);
      if (localItems.isNotEmpty) {
        return {
          'items': localItems.map((item) => item.toJson()).toList(),
          'totalCount': localItems.length,
          'hasNextPage': false,
        };
      }

      final localCached = await _localApiCache.getMap(key);
      if (localCached != null) {
        return localCached;
      }
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getImportDetail(int importId) async {
    final key = 'import_detail_$importId';
    try {
      final data = await _apiService.getImportDetail(importId);
      await _localApiCache.setMap(
        key,
        data,
        groupKey: 'imports',
        cacheType: 'detail',
      );
      await _localDataSource.upsertDetail(ImportDetailModel.fromJson(data));
      return data;
    } catch (e) {
      final localDetail = await _localDataSource.getById(importId);
      if (localDetail != null) {
        return localDetail.toJson();
      }

      final localCached = await _localApiCache.getMap(key);
      if (localCached != null) {
        return localCached;
      }
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createImport(CreateImportRequest request) async {
    try {
      final response = await _apiService.createImport(request);
      final payload = response['data'] as Map<String, dynamic>?;
      final detail = await _tryGetFreshImportDetail(_parseImportId(payload));
      if (detail != null) {
        return {...response, 'data': detail};
      }
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateImport(
    int importId,
    UpdateImportRequest request,
  ) async {
    try {
      final response = await _apiService.updateImport(importId, request);
      final payload = response['data'] as Map<String, dynamic>?;
      final detail = await _tryGetFreshImportDetail(
        _parseImportId(payload) ?? importId,
      );
      if (detail != null) {
        return {...response, 'data': detail};
      }
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> confirmImport(
    int importId,
    ConfirmImportRequest request,
  ) async {
    try {
      final response = await _apiService.confirmImport(importId, request);
      final payload = response['data'] as Map<String, dynamic>?;
      final detail = await _tryGetFreshImportDetail(
        _parseImportId(payload) ?? importId,
      );
      if (detail != null) {
        return {...response, 'data': detail};
      }
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteImport(int importId) async {
    try {
      final data = await _apiService.deleteImport(importId);
      await _localApiCache.removeByKey('import_detail_$importId');
      await _localDataSource.deleteById(importId);
      return data;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getImportTemplate() async {
    try {
      return await _apiService.getImportTemplate();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<OcrPurchaseInvoiceResultDto> ocrPurchaseInvoice({
    required int locationId,
    required File imageFile,
  }) {
    return _apiService.ocrPurchaseInvoice(
      locationId: locationId,
      imageFile: imageFile,
    );
  }
}
