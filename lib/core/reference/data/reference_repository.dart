import '../../../shared/cache/cache_manager.dart';
import 'reference_api_service.dart';

class ReferenceRepository {
  final ReferenceApiService _apiService;
  final CacheManager _cache;

  ReferenceRepository({
    required ReferenceApiService apiService,
    CacheManager? cacheManager,
  })  : _apiService = apiService,
        _cache = cacheManager ?? CacheManager();

  Future<void> getAllReferences({
    required Function(Map<String, List<String>> data, bool isFromCache) onData,
    Function(dynamic error)? onError,
  }) async {
    // Implement SWR logic using fetchWithSWR to fetch all reference enums in parallel
    await _cache.fetchWithSWR<Map<String, List<String>>>(
      key: 'reference_data',
      fetcher: () async {
        final results = await Future.wait([
          _apiService.getPaymentMethods(),
          _apiService.getBusinessTypeStatuses(),
          _apiService.getCostTypes(),
          _apiService.getGeneralLedgerReferenceTypes(),
          _apiService.getGeneralLedgerTransactionTypes(),
          _apiService.getGeneralLedgerViewModes(),
          _apiService.getImportStatuses(),
          _apiService.getImportTypes(),
          _apiService.getMoneyChannelTypes(),
          _apiService.getOrderStatuses(),
          _apiService.getProductStatuses(),
          _apiService.getRevenueTypes(),
          _apiService.getStockMovementTypes(),
          _apiService.getStockMovementReferenceTypes(),
        ]);

        return {
          'paymentMethods': results[0],
          'businessTypeStatuses': results[1],
          'costTypes': results[2],
          'generalLedgerReferenceTypes': results[3],
          'generalLedgerTransactionTypes': results[4],
          'generalLedgerViewModes': results[5],
          'importStatuses': results[6],
          'importTypes': results[7],
          'moneyChannelTypes': results[8],
          'orderStatuses': results[9],
          'productStatuses': results[10],
          'revenueTypes': results[11],
          'stockMovementTypes': results[12],
          'stockMovementReferenceTypes': results[13],
        };
      },
      onData: onData,
      onError: onError,
      toJson: (data) => data,
      fromJson: (json) {
        final map = json;
        return map.map((key, value) {
          final list = value is List ? value.map((e) => e.toString()).toList() : <String>[];
          return MapEntry(key, list);
        });
      },
    );
  }
}
