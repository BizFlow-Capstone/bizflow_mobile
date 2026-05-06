import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/cache/local_api_cache_store.dart';
import '../domain/entities/revenue_entity.dart';
import 'revenue_api_service.dart';
import 'models/ai_draft_revenue_dto.dart';
import 'models/revenue_dto.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RevenueRepository {
  final RevenueApiService _apiService;
  final CacheManager _cache;
  final LocalApiCacheStore _localApiCache;

  RevenueRepository({
    required RevenueApiService apiService,
    CacheManager? cacheManager,
    LocalApiCacheStore? localApiCacheStore,
  }) : _apiService = apiService,
       _cache = cacheManager ?? CacheManager(),
       _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  RevenueEntity _mapToEntity(RevenueDto dto) {
    return RevenueEntity(
      id: dto.revenueId,
      locationId: dto.businessLocationId,
      type: dto.revenueType,
      amount: dto.amount,
      date: dto.revenueDate,
      documentDate: dto.documentDate,
      description: dto.description,
      moneyChannel: dto.moneyChannel,
      referenceType: dto.referenceType,
      referenceId: dto.referenceId,
      referenceCode: dto.referenceCode,
      revenueCode: dto.revenueCode,
      businessTypeId: dto.businessTypeId,
      businessTypeName: dto.businessTypeName,
      documentNumber: dto.documentNumber,
      statusCode: dto.statusCode,
      statusLabel: dto.statusLabel,
      imagePath: dto.imagePath,
      createdAt: dto.createdAt,
    );
  }

  String _buildCacheKey(int locationId, int page, int size) {
    return 'revenues_${locationId}_p${page}_s${size}';
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
    final key = _buildCacheKey(businessLocationId ?? 0, pageNumber, pageSize);
    debugPrint(
      '[RevenueRepository] getRevenuesSWR start '
      'key=$key locationId=$businessLocationId page=$pageNumber size=$pageSize',
    );

    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      final items = (localCached['items'] as List<dynamic>? ?? [])
          .map((e) => RevenueDto.fromJson(e as Map<String, dynamic>))
          .map(_mapToEntity)
          .toList();
      final totalCount = localCached['total'] as int? ?? 0;
      debugPrint(
        '[RevenueRepository] local cache hit key=$key items=${items.length} total=$totalCount',
      );
      onData(items, totalCount, true);
    } else {
      debugPrint('[RevenueRepository] local cache miss key=$key');
    }

    await _cache.fetchWithSWR<Map<String, dynamic>>(
      key: key,
      fetcher: ({cancelToken}) => _apiService
          .getRevenues(
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
          groupKey: 'revenues',
          cacheType: 'list',
        );
        final items = (dataMap['items'] as List<dynamic>? ?? [])
            .map((e) => RevenueDto.fromJson(e as Map<String, dynamic>))
            .map(_mapToEntity)
            .toList();
        final totalCount = dataMap['total'] as int? ?? 0;
        debugPrint(
          '[RevenueRepository] swr onData key=$key fromCache=$isFromCache items=${items.length} total=$totalCount',
        );
        onData(items, totalCount, isFromCache);
      },
      onError: (error) {
        debugPrint('[RevenueRepository] swr onError key=$key error=$error');
        onError?.call(error);
      },
      toJson: (data) => data,
      fromJson: (json) => json,
    );
  }

  Future<void> clearCache() async {
    await _cache.removeByPrefix('revenues_');
    await _localApiCache.removeByGroup('revenues');
  }

  Future<RevenueEntity> createManualRevenue(
    Map<String, dynamic> body, {
    File? image,
  }) async {
    final dto = await _apiService.createManualRevenue(body, image: image);
    await clearCache();
    return _mapToEntity(dto);
  }

  Future<RevenueEntity> updateManualRevenue(
    int revenueId,
    Map<String, dynamic> body, {
    String? idempotencyKey,
    File? image,
  }) async {
    final dto = await _apiService.updateManualRevenue(
      revenueId,
      body,
      image: image,
      idempotencyKey: idempotencyKey,
    );
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

  Future<AiDraftRevenueResultDto> parseDraftRevenueFromAudio({
    required int locationId,
    required File audioFile,
  }) {
    return _apiService.parseDraftRevenueFromAudio(
      locationId: locationId,
      audioFile: audioFile,
    );
  }
}
