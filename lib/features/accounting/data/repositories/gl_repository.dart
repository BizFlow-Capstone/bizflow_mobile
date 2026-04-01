import '../../../../shared/cache/cache_manager.dart';
import '../services/gl_api_service.dart';
import '../models/general_ledger_entry_model.dart';

class GLRepository {
  final GLApiService _apiService;
  final CacheManager _cache;

  GLRepository({
    required GLApiService apiService,
    CacheManager? cacheManager,
  })  : _apiService = apiService,
        _cache = cacheManager ?? CacheManager();

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

    await _cache.fetchWithSWR<Map<String, dynamic>>(
      key: key,
      fetcher: ({cancelToken}) => _apiService.getGLEntries(
        businessLocationId: businessLocationId,
        pageNumber: pageNumber,
        pageSize: pageSize,
        transactionTypes: transactionTypes,
        referenceTypes: referenceTypes,
        moneyChannels: moneyChannels,
        fromDate: fromDate,
        toDate: toDate,
        viewMode: viewMode,
      ),
      onData: (dataMap, isFromCache) {
        final items = (dataMap['items'] as List<dynamic>? ?? [])
            .map((e) => GeneralLedgerEntryModel.fromJson(e))
            .toList();
        final totalCount = dataMap['totalCount'] as int? ?? 0;
        onData(items, totalCount, isFromCache);
      },
      onError: onError,
      toJson: (data) => data,
      fromJson: (json) => json,
    );
  }
}
