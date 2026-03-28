import '../../../../shared/cache/cache_manager.dart';
import '../domain/entities/revenue_entity.dart';
import 'revenue_api_service.dart';
import 'models/revenue_dto.dart';

class RevenueRepository {
  final RevenueApiService _apiService;
  final CacheManager _cache;

  RevenueRepository({
    required RevenueApiService apiService,
    CacheManager? cacheManager,
  })  : _apiService = apiService,
        _cache = cacheManager ?? CacheManager();

  RevenueEntity _mapToEntity(RevenueDto dto) {
    return RevenueEntity(
      id: dto.revenueId,
      locationId: dto.businessLocationId,
      type: dto.revenueType,
      amount: dto.amount,
      date: dto.revenueDate,
      description: dto.description,
      moneyChannel: dto.moneyChannel,
      referenceType: dto.referenceType,
      referenceId: dto.referenceId,
      referenceCode: dto.referenceCode,
      createdAt: dto.createdAt,
    );
  }

  Future<void> getRevenuesSWR({
    required int pageNumber,
    required int pageSize,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    required Function(
      List<RevenueEntity> data,
      int totalCount,
      bool isFromCache,
    )
    onData,
    Function(dynamic error)? onError,
  }) async {
    final key = 'revenues_${businessLocationId}_p${pageNumber}_s$pageSize';

    await _cache.fetchWithSWR<Map<String, dynamic>>(
      key: key,
      fetcher:
            ({cancelToken}) => _apiService
              .getRevenues(
                pageNumber: pageNumber,
                pageSize: pageSize,
                businessLocationId: businessLocationId,
                fromDate: fromDate,
                toDate: toDate,
              )
              .then((res) => {
                'items': res.items.map((e) => e.toJson()).toList(),
                'total': res.totalCount,
              }),
      onData: (dataMap, isFromCache) {
        final items =
            (dataMap['items'] as List<dynamic>? ?? [])
                .map((e) => RevenueDto.fromJson(e as Map<String, dynamic>))
                .map(_mapToEntity)
                .toList();
        final totalCount = dataMap['total'] as int? ?? 0;
        onData(items, totalCount, isFromCache);
      },
      onError: onError,
      toJson: (data) => data,
      fromJson: (json) => json,
    );
  }

  Future<void> clearCache() async {
    await _cache.removeByPrefix('revenues_');
  }

  Future<RevenueEntity> createManualRevenue(Map<String, dynamic> body) async {
    final dto = await _apiService.createManualRevenue(body);
    await clearCache();
    return _mapToEntity(dto);
  }

  Future<bool> deleteManualRevenue(int revenueId) async {
    final result = await _apiService.deleteManualRevenue(revenueId);
    if (result) {
      await clearCache();
    }
    return result;
  }
}
