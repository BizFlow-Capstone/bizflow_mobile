import '../../../shared/cache/cache_manager.dart';
import 'reference_api_service.dart';
import 'reference_item.dart';

class ReferenceRepository {
  final ReferenceApiService _apiService;
  final CacheManager _cache;

  ReferenceRepository({
    required ReferenceApiService apiService,
    CacheManager? cacheManager,
  })  : _apiService = apiService,
        _cache = cacheManager ?? CacheManager();

  /// Buộc SWR revalidate ngầm lần tới mà không xóa cache.
  /// Nếu network fail, data cũ vẫn được serve — tránh UI trống khi mất mạng.
  void scheduleForceRevalidate() {
    _cache.resetRevalidateTimer('reference_data');
  }

  Future<void> getAllReferences({
    required Function(Map<String, List<ReferenceItem>> data, bool isFromCache) onData,
    Function(dynamic error)? onError,
  }) async {
    await _cache.fetchWithSWR<Map<String, List<ReferenceItem>>>(
      key: 'reference_data',
      fetcher: ({cancelToken}) async {
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
      toJson: (data) => data.map(
        (key, items) => MapEntry(key, items.map((i) => i.toJson()).toList()),
      ),
      fromJson: (json) => json.map((key, value) {
        final list = value is List
            ? value.map((e) {
                if (e is Map<String, dynamic>) return ReferenceItem.fromJson(e);
                final str = e?.toString() ?? '';
                return ReferenceItem(code: str, label: str);
              }).toList()
            : <ReferenceItem>[];
        return MapEntry(key, list);
      }),
    );
  }
}
