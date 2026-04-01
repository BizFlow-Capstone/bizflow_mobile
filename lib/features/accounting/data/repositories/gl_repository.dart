import '../../../../shared/cache/local_api_cache_store.dart';
import '../services/gl_api_service.dart';
import '../models/general_ledger_entry_model.dart';

class GLRepository {
  final GLApiService _apiService;
  final LocalApiCacheStore _localApiCache;

  GLRepository({
    required GLApiService apiService,
    LocalApiCacheStore? localApiCacheStore,
  })  : _apiService = apiService,
        _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  Future<void> fetchGLEntriesSWR({
    required int businessLocationId,
    required int pageNumber,
    required int pageSize,
    List<String>? transactionTypes,
    List<String>? referenceTypes,
    List<String>? moneyChannels,
    DateTime? fromDate,
    DateTime? toDate,
    String viewMode = 'audit',
    required Function(List<GeneralLedgerEntryModel> data, int totalCount, bool isFromCache) onData,
    Function(dynamic error)? onError,
  }) async {
    // Generate cache key
    final filterKey = '${transactionTypes?.join('-')}_${referenceTypes?.join('-')}_${moneyChannels?.join('-')}_${fromDate?.toIso8601String()}_${toDate?.toIso8601String()}_$viewMode';
    final key = 'gl_entries_${businessLocationId}_p${pageNumber}_s${pageSize}_$filterKey';
    var hasLocalData = false;
    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      final items = (localCached['items'] as List<dynamic>? ?? [])
          .map((e) => GeneralLedgerEntryModel.fromJson(e))
          .toList();
      final totalCount = localCached['totalCount'] as int? ?? 0;
      onData(items, totalCount, true);
      hasLocalData = true;
    }

    try {
      final dataMap = await _apiService.getGLEntries(
        businessLocationId: businessLocationId,
        pageNumber: pageNumber,
        pageSize: pageSize,
        transactionTypes: transactionTypes,
        referenceTypes: referenceTypes,
        moneyChannels: moneyChannels,
        fromDate: fromDate,
        toDate: toDate,
        viewMode: viewMode,
      );
      await _localApiCache.setMap(
        key,
        dataMap,
        groupKey: 'gl_entries',
        cacheType: 'list',
      );
      final items = (dataMap['items'] as List<dynamic>? ?? [])
          .map((e) => GeneralLedgerEntryModel.fromJson(e))
          .toList();
      final totalCount = dataMap['totalCount'] as int? ?? 0;
      onData(items, totalCount, false);
    } catch (error) {
      if (!hasLocalData && onError != null) {
        onError(error);
      }
    }
  }
}
