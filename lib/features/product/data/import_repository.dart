import 'datasources/import_local_datasource.dart';
import 'import_api_service.dart';
import 'models/import_model.dart';
import '../../../shared/cache/local_api_cache_store.dart';

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
      final payload = response['data'];
      if (payload is Map<String, dynamic>) {
        await _localDataSource.upsertDetail(
          ImportDetailModel.fromJson(payload),
        );
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
      final payload = response['data'];
      if (payload is Map<String, dynamic>) {
        await _localDataSource.upsertDetail(
          ImportDetailModel.fromJson(payload),
        );
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
      final payload = response['data'];
      if (payload is Map<String, dynamic>) {
        await _localDataSource.upsertDetail(
          ImportDetailModel.fromJson(payload),
        );
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
}
