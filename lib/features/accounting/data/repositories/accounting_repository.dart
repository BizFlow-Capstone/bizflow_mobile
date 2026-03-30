import 'package:flutter/foundation.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../domain/models/accounting_period.dart';
import '../../domain/models/accounting_book.dart';
import '../services/accounting_api_service.dart';

class AccountingRepository {
  final AccountingApiService _apiService;
  final CacheManager _cache;

  AccountingRepository({
    required AccountingApiService apiService,
    CacheManager? cacheManager,
  })  : _apiService = apiService,
        _cache = cacheManager ?? CacheManager();

  String _periodsKey(String locationId) => 'periods_$locationId';
  String _periodDetailKey(String locationId, String periodId) =>
      'period_detail_${locationId}_$periodId';

  // ──────────────────────────────────────────────────────
  // SWR: List Periods
  // ──────────────────────────────────────────────────────

  /// Trả về cached list (nếu có) rồi fetch ngầm từ API.
  /// Gọi [onData] 1–2 lần: 1 lần cho cache, 1 lần cho server.
  Future<void> fetchPeriodsSWR({
    required String locationId,
    required void Function(List<AccountingPeriod> periods, bool fromCache)
        onData,
    void Function(dynamic error)? onError,
  }) async {
    await _cache.fetchWithSWR<List<AccountingPeriod>>(
      key: _periodsKey(locationId),
        fetcher: ({cancelToken}) => _apiService.listPeriods(locationId),
      onData: onData,
      onError: onError,
      fromJson: (json) {
        final list = json['items'] as List<dynamic>? ?? [];
        return list
            .map(
              (e) =>
                  AccountingPeriod.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      },
      toJson: (periods) => {
        'items': periods.map((p) => p.toJson()).toList(),
      },
    );
  }

  // ──────────────────────────────────────────────────────
  // Create Period (quarter / year)
  // ──────────────────────────────────────────────────────

  Future<AccountingPeriod> createPeriod({
    required String locationId,
    required String periodType,
    required int year,
    int? quarter,
    double? openingCashBalance,
    double? openingBankBalance,
    bool useSuggestedOpeningBalances = false,
  }) async {
    final body = <String, dynamic>{
      'periodType': periodType,
      'year': year,
      if (quarter != null) 'quarter': quarter,
      if (openingCashBalance != null)
        'openingCashBalance': openingCashBalance,
      if (openingBankBalance != null)
        'openingBankBalance': openingBankBalance,
      'useSuggestedOpeningBalances': useSuggestedOpeningBalances,
    };

    final created = await _apiService.createPeriod(locationId, body);
    await _invalidateCache(locationId);
    return created;
  }

  // ──────────────────────────────────────────────────────
  // Create Custom Period
  // ──────────────────────────────────────────────────────

  Future<AccountingPeriod> createCustomPeriod({
    required String locationId,
    required String startDate,
    required String endDate,
    double? openingCashBalance,
    double? openingBankBalance,
    bool useSuggestedOpeningBalances = false,
  }) async {
    final body = <String, dynamic>{
      'startDate': startDate,
      'endDate': endDate,
      if (openingCashBalance != null)
        'openingCashBalance': openingCashBalance,
      if (openingBankBalance != null)
        'openingBankBalance': openingBankBalance,
      'useSuggestedOpeningBalances': useSuggestedOpeningBalances,
    };

    final created = await _apiService.createCustomPeriod(locationId, body);
    await _invalidateCache(locationId);
    return created;
  }

  // ──────────────────────────────────────────────────────
  // Opening Balance Suggestion
  // ──────────────────────────────────────────────────────

  Future<OpeningBalanceSuggestion> getOpeningBalanceSuggestion({
    required String locationId,
    required String periodType,
    int? year,
    int? quarter,
    String? startDate,
  }) async {
    final body = <String, dynamic>{
      'periodType': periodType,
      if (year != null) 'year': year,
      if (quarter != null) 'quarter': quarter,
      if (startDate != null) 'startDate': startDate,
    };
    return _apiService.getOpeningBalanceSuggestion(locationId, body);
  }

  // ──────────────────────────────────────────────────────
  // Period Detail
  // ──────────────────────────────────────────────────────

  Future<AccountingPeriod> getPeriodDetail({
    required String locationId,
    required String periodId,
  }) async {
    return _apiService.getPeriodDetail(locationId, periodId);
  }

  /// SWR cho period detail: trả cache trước rồi sync ngầm từ server
  Future<void> fetchPeriodDetailSWR({
    required String locationId,
    required String periodId,
    required void Function(AccountingPeriod period, bool fromCache) onData,
    void Function(dynamic error)? onError,
  }) async {
    await _cache.fetchWithSWR<AccountingPeriod>(
      key: _periodDetailKey(locationId, periodId),
        fetcher: ({cancelToken}) => _apiService.getPeriodDetail(locationId, periodId),
      onData: onData,
      onError: onError,
      fromJson: (json) => AccountingPeriod.fromJson(json),
      toJson: (period) => period.toJson(),
    );
  }

  // ──────────────────────────────────────────────────────
  // Finalize Period
  // ──────────────────────────────────────────────────────

  Future<void> finalizePeriod({
    required String locationId,
    required String periodId,
  }) async {
    try {
      await _apiService.finalizePeriod(locationId, periodId);
    } catch (e) {
      if (e.toString().contains('__refresh_required__')) {
        // success but no data in response, just invalidate cache
        await _invalidateCache(locationId);
        return;
      }
      rethrow;
    }
    await _invalidateCache(locationId);
  }

  // ──────────────────────────────────────────────────────
  // Reopen Period
  // ──────────────────────────────────────────────────────

  Future<void> reopenPeriod({
    required String locationId,
    required String periodId,
    required String reason,
  }) async {
    await _apiService.reopenPeriod(locationId, periodId, reason);
    await _invalidateCache(locationId);
  }

  // ──────────────────────────────────────────────────────
  // Audit Logs
  // ──────────────────────────────────────────────────────

  Future<List<AccountingPeriodAuditLog>> getAuditLogs({
    required String locationId,
    required String periodId,
  }) async {
    return _apiService.getAuditLogs(locationId, periodId);
  }

  // ──────────────────────────────────────────────────────
  // Create Accounting Books (TT152 templates)
  // ──────────────────────────────────────────────────────

  /// Create books from selected template codes for a period
  /// Required: periodId, groupNumber, taxMethod, templateCodes[]
  /// Example templateCodes per group:
  /// - Group 1: ["S1a"]
  /// - Group 2 + method_1: ["S2a"]
  /// - Group 2-4 + method_2: ["S2b", "S2c", "S2d", "S2e"]
  Future<CreateBooksResponse> createBooksForPeriod({
    required String locationId,
    required Map<String, dynamic> body,
  }) async {
    return _apiService.createBooksForPeriod(locationId, body);
  }

  /// Get books for specific period with SWR pattern
  Future<void> fetchBooksForPeriodSWR({
    required String locationId,
    required String periodId,
    required void Function(List<AccountingBook> books, bool fromCache) onData,
    void Function(dynamic error)? onError,
  }) async {
    final cacheKey = 'books_${locationId}_$periodId';
    await _cache.fetchWithSWR<List<AccountingBook>>(
      key: cacheKey,
      fetcher: ({cancelToken}) =>
          _apiService.listBooks(locationId, periodId: periodId),
      onData: onData,
      onError: onError,
      fromJson: (json) {
        final list = json['items'] as List<dynamic>? ?? [];
        return list
            .map((e) => AccountingBook.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      toJson: (books) => {
        'items': books.map((b) => b.toJson()).toList(),
      },
    );
  }

  Future<List<AccountingBook>> listBooks({
    required String locationId,
    String? periodId,
  }) async {
    return _apiService.listBooks(locationId, periodId: periodId);
  }

  /// Direct server fetch for books (used after book creation)
  Future<List<AccountingBook>> fetchBooksFromServer({
    required String locationId,
    required String periodId,
  }) async {
    return _apiService.listBooks(locationId, periodId: periodId);
  }

  /// ──────────────────────────────────────────────────────
  /// Direct server fetch (used after mutations to refresh list)
  Future<List<AccountingPeriod>> fetchPeriodsFromServer(
    String locationId,
  ) async {
    final periods = await _apiService.listPeriods(locationId);
    // Update cache with fresh data
    try {
      await _cache.set(_periodsKey(locationId), {
        'items': periods.map((p) => p.toJson()).toList(),
      });
    } catch (_) {}
    return periods;
  }

  // ──────────────────────────────────────────────────────
  // Get Book Rows (for rendering template & export)
  // ──────────────────────────────────────────────────────

  Future<BookRowsResponse> getBookRows({
    required String locationId,
    required String bookId,
    String? cursor,
    int batchSize = 200,
  }) async {
    return _apiService.getBookRows(
      locationId,
      bookId,
      cursor: cursor,
      batchSize: batchSize,
    );
  }

  // ──────────────────────────────────────────────────────
  // Cache helpers
  // ──────────────────────────────────────────────────────

  Future<void> _invalidateCache(String locationId) async {
    try {
      await _cache.remove(_periodsKey(locationId));
    } catch (e) {
      debugPrint('AccountingRepository._invalidateCache error: $e');
    }
  }
}
