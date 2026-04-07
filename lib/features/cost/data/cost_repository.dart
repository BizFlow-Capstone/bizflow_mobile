import 'dart:io';
import '../../../shared/cache/cache_manager.dart';
import '../../../shared/cache/local_api_cache_store.dart';
import '../domain/entities/cost_entity.dart';
import 'cost_api_service.dart';
import 'models/ai_draft_cost_dto.dart';
import 'models/cost_dto.dart';

class CostRepository {
  final CostApiService _apiService;
  final CacheManager _cache;
  final LocalApiCacheStore _localApiCache;

  CostRepository({
    required CostApiService apiService,
    CacheManager? cacheManager,
    LocalApiCacheStore? localApiCacheStore,
  }) : _apiService = apiService,
       _cache = cacheManager ?? CacheManager(),
       _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  CostEntity _mapToEntity(CostDto dto) {
    return CostEntity(
      id: dto.costId,
      locationId: dto.businessLocationId,
      type: dto.costType,
      amount: dto.amount,
      date: dto.costDate,
      documentDate: dto.documentDate,
      description: dto.description,
      paymentMethod: dto.paymentMethod,
      documentUrl: dto.documentUrl,
      referenceType: dto.referenceType,
      referenceId: dto.referenceId,
      referenceCode: dto.referenceCode,
      createdAt: dto.createdAt,
    );
  }

  Future<void> getCostsSWR({
    required int pageNumber,
    required int pageSize,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    required Function(List<CostEntity> data, int totalCount, bool isFromCache)
    onData,
    Function(dynamic error)? onError,
  }) async {
    final key = 'costs_${businessLocationId}_p${pageNumber}_s$pageSize';
    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      final items = (localCached['items'] as List<dynamic>? ?? [])
          .map((e) => CostDto.fromJson(e as Map<String, dynamic>))
          .map(_mapToEntity)
          .toList();
      final totalCount = localCached['total'] as int? ?? 0;
      onData(items, totalCount, true);
    }

    await _cache.fetchWithSWR<Map<String, dynamic>>(
      key: key,
      fetcher: ({cancelToken}) => _apiService
          .getCosts(
            pageNumber: pageNumber,
            pageSize: pageSize,
            businessLocationId: businessLocationId,
            fromDate: fromDate,
            toDate: toDate,
          )
          .then(
            (res) => {
              'items': res.items.map((e) => e.toJson()).toList(),
              'total': res.totalCount,
            },
          ),
      onData: (dataMap, isFromCache) {
        _localApiCache.setMap(
          key,
          dataMap,
          groupKey: 'costs',
          cacheType: 'list',
        );
        final items = (dataMap['items'] as List<dynamic>? ?? [])
            .map((e) => CostDto.fromJson(e as Map<String, dynamic>))
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
    await _cache.removeByPrefix('costs_');
    await _localApiCache.removeByGroup('costs');
  }

  Future<CostEntity> createManualCost(
    Map<String, dynamic> body, {
    File? image,
  }) async {
    final dto = await _apiService.createManualCost(body, image: image);
    await clearCache();
    return _mapToEntity(dto);
  }

  Future<CostEntity> updateManualCost(
    int costId,
    Map<String, dynamic> body, {
    File? image,
  }) async {
    final dto = await _apiService.updateManualCost(costId, body, image: image);
    await clearCache();
    return _mapToEntity(dto);
  }

  Future<bool> deleteManualCost(int costId) async {
    final result = await _apiService.deleteManualCost(costId);
    if (result) {
      await clearCache();
    }
    return result;
  }

  Future<AiDraftCostResultDto> parseDraftCostFromAudio({
    required int locationId,
    required File audioFile,
  }) {
    return _apiService.parseDraftCostFromAudio(
      locationId: locationId,
      audioFile: audioFile,
    );
  }
}
