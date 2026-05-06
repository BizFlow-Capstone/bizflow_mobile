import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/cache/local_api_cache_store.dart';
import '../../domain/models/accounting_period.dart';
import '../../domain/models/accounting_book.dart';
import '../services/accounting_api_service.dart';

class AccountingRepository {
  final AccountingApiService _apiService;
  final LocalApiCacheStore _localApiCache;

  AccountingRepository({
    required AccountingApiService apiService,
    LocalApiCacheStore? localApiCacheStore,
  }) : _apiService = apiService,
       _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  String _periodsKey(String locationId) => 'periods_$locationId';
  String _periodDetailKey(String locationId, String periodId) =>
      'period_detail_${locationId}_$periodId';
  String _booksKey(String locationId, String? periodId) =>
      'books_${locationId}_${periodId ?? 'all'}';
  String _bookRowsKey(
    String locationId,
    String bookId,
    String? cursor,
    int batchSize,
  ) => 'book_rows_${locationId}_${bookId}_${cursor ?? 'first'}_$batchSize';
  String _bookSectionsKey(String locationId, String bookId) =>
      'book_sections_${locationId}_$bookId';
  String _auditLogsKey(String locationId, String periodId) =>
      'audit_logs_${locationId}_$periodId';

  static const String _periodsSyncResourceKey = 'accounting_periods_list';
  static const String _booksSyncResourceKey = 'accounting_books_list';

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
    var hasLocalData = false;
    final localCached = await _localApiCache.getMap(_periodsKey(locationId));
    if (localCached != null) {
      final list = localCached['items'] as List<dynamic>? ?? [];
      final periods = list
          .map((e) => AccountingPeriod.fromJson(e as Map<String, dynamic>))
          .toList();
      onData(periods, true);
      hasLocalData = true;
    }

    try {
      final periods = await _apiService.listPeriods(locationId);
      await _localApiCache.setMap(
        _periodsKey(locationId),
        {'items': periods.map((p) => p.toJson()).toList()},
        groupKey: 'accounting_periods',
        cacheType: 'list',
      );
      await AppDatabase().syncStateDao.upsert(
        resourceKey: _periodsSyncResourceKey,
        businessId: locationId,
        lastSyncedAtEpoch: DateTime.now().millisecondsSinceEpoch,
      );
      onData(periods, false);
    } catch (error) {
      if (!hasLocalData && onError != null) {
        onError(error);
      }
    }
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
      if (openingCashBalance != null) 'openingCashBalance': openingCashBalance,
      if (openingBankBalance != null) 'openingBankBalance': openingBankBalance,
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
      if (openingCashBalance != null) 'openingCashBalance': openingCashBalance,
      if (openingBankBalance != null) 'openingBankBalance': openingBankBalance,
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
    final key = _periodDetailKey(locationId, periodId);
    try {
      final period = await _apiService.getPeriodDetail(locationId, periodId);
      await _localApiCache.setMap(
        key,
        period.toJson(),
        groupKey: 'accounting_periods',
        cacheType: 'detail',
      );
      return period;
    } catch (e) {
      final localCached = await _localApiCache.getMap(key);
      if (localCached != null) {
        return AccountingPeriod.fromJson(localCached);
      }
      rethrow;
    }
  }

  /// SWR cho period detail: trả cache trước rồi sync ngầm từ server
  Future<void> fetchPeriodDetailSWR({
    required String locationId,
    required String periodId,
    required void Function(AccountingPeriod period, bool fromCache) onData,
    void Function(dynamic error)? onError,
  }) async {
    final key = _periodDetailKey(locationId, periodId);
    var hasLocalData = false;
    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      onData(AccountingPeriod.fromJson(localCached), true);
      hasLocalData = true;
    }

    try {
      final period = await _apiService.getPeriodDetail(locationId, periodId);
      await _localApiCache.setMap(
        key,
        period.toJson(),
        groupKey: 'accounting_periods',
        cacheType: 'detail',
      );
      onData(period, false);
    } catch (error) {
      if (!hasLocalData && onError != null) {
        onError(error);
      }
    }
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

  /// SWR for audit logs: return cached logs immediately if available,
  /// then refresh from server in background.
  Future<void> fetchAuditLogsSWR({
    required String locationId,
    required String periodId,
    required void Function(List<AccountingPeriodAuditLog> logs, bool fromCache)
    onData,
    void Function(dynamic error)? onError,
  }) async {
    final key = _auditLogsKey(locationId, periodId);
    var hasLocalData = false;

    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      final list = localCached['items'] as List<dynamic>? ?? [];
      final logs = list
          .map(
            (e) => AccountingPeriodAuditLog.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      onData(logs, true);
      hasLocalData = true;
    }

    try {
      final logs = await _apiService.getAuditLogs(locationId, periodId);
      await _localApiCache.setMap(
        key,
        {
          'items': logs
              .map(
                (log) => {
                  'logId': log.logId,
                  'periodId': log.periodId,
                  'action': log.action,
                  'oldValue': log.oldValue,
                  'newValue': log.newValue,
                  'reason': log.reason,
                  'createdAt': log.createdAt.toIso8601String(),
                },
              )
              .toList(),
        },
        groupKey: 'accounting_period_audit_logs',
        cacheType: 'list',
      );
      onData(logs, false);
    } catch (error) {
      if (!hasLocalData && onError != null) {
        onError(error);
      }
    }
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
    String? periodId,
    required void Function(List<AccountingBook> books, bool fromCache) onData,
    void Function(dynamic error)? onError,
  }) async {
    final cacheKey = _booksKey(locationId, periodId);
    final booksScopeKey = '${locationId}_${periodId ?? 'all'}';
    var hasLocalData = false;
    final localCached = await _localApiCache.getMap(cacheKey);
    if (localCached != null) {
      final list = localCached['items'] as List<dynamic>? ?? [];
      final books = list
          .map((e) => AccountingBook.fromJson(e as Map<String, dynamic>))
          .toList();
      onData(books, true);
      hasLocalData = true;
    }

    try {
      final books = await _apiService.listBooks(locationId, periodId: periodId);
      await _localApiCache.setMap(
        cacheKey,
        {'items': books.map((b) => b.toJson()).toList()},
        groupKey: 'accounting_books',
        cacheType: 'list',
      );
      await AppDatabase().syncStateDao.upsert(
        resourceKey: _booksSyncResourceKey,
        businessId: booksScopeKey,
        lastSyncedAtEpoch: DateTime.now().millisecondsSinceEpoch,
      );
      onData(books, false);
    } catch (error) {
      if (!hasLocalData && onError != null) {
        onError(error);
      }
    }
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

  Future<void> deleteBook({
    required String locationId,
    required String bookId,
  }) async {
    await _apiService.deleteBook(locationId, bookId);
    await _invalidateCache(locationId);
  }

  /// ──────────────────────────────────────────────────────
  /// Direct server fetch (used after mutations to refresh list)
  Future<List<AccountingPeriod>> fetchPeriodsFromServer(
    String locationId,
  ) async {
    final periods = await _apiService.listPeriods(locationId);
    await _localApiCache.setMap(
      _periodsKey(locationId),
      {'items': periods.map((p) => p.toJson()).toList()},
      groupKey: 'accounting_periods',
      cacheType: 'list',
    );
    await AppDatabase().syncStateDao.upsert(
      resourceKey: _periodsSyncResourceKey,
      businessId: locationId,
      lastSyncedAtEpoch: DateTime.now().millisecondsSinceEpoch,
    );
    return periods;
  }

  Future<int?> getPeriodsLastSyncedAtEpoch(String locationId) async {
    final state = await AppDatabase().syncStateDao.getState(
      resourceKey: _periodsSyncResourceKey,
      businessId: locationId,
    );
    return state?.lastSyncedAtEpoch;
  }

  Future<int?> getBooksLastSyncedAtEpoch({
    required String locationId,
    required String periodId,
  }) async {
    final state = await AppDatabase().syncStateDao.getState(
      resourceKey: _booksSyncResourceKey,
      businessId: '${locationId}_$periodId',
    );
    return state?.lastSyncedAtEpoch;
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
    final key = _bookRowsKey(locationId, bookId, cursor, batchSize);
    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      unawaited(
        _refreshBookRowsCache(
          key: key,
          locationId: locationId,
          bookId: bookId,
          cursor: cursor,
          batchSize: batchSize,
        ),
      );
      return BookRowsResponse.fromJson(localCached);
    }

    try {
      final rows = await _apiService.getBookRows(
        locationId,
        bookId,
        cursor: cursor,
        batchSize: batchSize,
      );
      await _localApiCache.setMap(
        key,
        _bookRowsResponseToJson(rows),
        groupKey: 'accounting_book_rows',
        cacheType: 'list',
      );
      return rows;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshBookRowsCache({
    required String key,
    required String locationId,
    required String bookId,
    required String? cursor,
    required int batchSize,
  }) async {
    try {
      final rows = await _apiService.getBookRows(
        locationId,
        bookId,
        cursor: cursor,
        batchSize: batchSize,
      );
      await _localApiCache.setMap(
        key,
        _bookRowsResponseToJson(rows),
        groupKey: 'accounting_book_rows',
        cacheType: 'list',
      );
    } catch (_) {
      // Best effort background refresh.
    }
  }

  // ──────────────────────────────────────────────────────
  // Get Book Sections (template-aware structured data)
  // ──────────────────────────────────────────────────────

  Future<BookSectionsResponse> getBookSections({
    required String locationId,
    required String bookId,
  }) async {
    final key = _bookSectionsKey(locationId, bookId);
    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      unawaited(
        _refreshBookSectionsCache(
          key: key,
          locationId: locationId,
          bookId: bookId,
        ),
      );
      return BookSectionsResponse.fromJson(localCached);
    }

    try {
      final sections = await _apiService.getBookSections(locationId, bookId);
      await _localApiCache.setMap(
        key,
        _bookSectionsResponseToJson(sections),
        groupKey: 'accounting_book_sections',
        cacheType: 'detail',
      );
      return sections;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshBookSectionsCache({
    required String key,
    required String locationId,
    required String bookId,
  }) async {
    try {
      final sections = await _apiService.getBookSections(locationId, bookId);
      await _localApiCache.setMap(
        key,
        _bookSectionsResponseToJson(sections),
        groupKey: 'accounting_book_sections',
        cacheType: 'detail',
      );
    } catch (_) {
      // Best effort background refresh.
    }
  }

  // ──────────────────────────────────────────────────────
  // Cache helpers
  // ──────────────────────────────────────────────────────

  Future<void> _invalidateCache(String locationId) async {
    try {
      await _localApiCache.removeByKey(_periodsKey(locationId));
      await _localApiCache.removeByGroup('accounting_periods');
      await _localApiCache.removeByGroup('accounting_books');
      await _localApiCache.removeByGroup('accounting_book_rows');
      await _localApiCache.removeByGroup('accounting_book_sections');
      await _localApiCache.removeByGroup('accounting_period_audit_logs');
    } catch (e) {
      debugPrint('AccountingRepository._invalidateCache error: $e');
    }
  }

  Map<String, dynamic> _bookRowsResponseToJson(BookRowsResponse value) {
    return {
      'rows': value.rows,
      'hasMore': value.hasMore,
      'nextCursor': value.nextCursor,
      'loadedCount': value.loadedCount,
      'totalEstimated': value.totalEstimated,
    };
  }

  Map<String, dynamic> _bookSectionsResponseToJson(BookSectionsResponse value) {
    return {
      'bookId': value.bookId,
      'templateCode': value.templateCode,
      'templateName': value.templateName,
      'lastCalculatedAt': value.lastCalculatedAt.toIso8601String(),
      'columns': value.columns
          .map(
            (column) => {
              'fieldCode': column.fieldCode,
              'label': column.label,
              'fieldType': column.fieldType,
              'exportColumn': column.exportColumn,
            },
          )
          .toList(),
      'sections': value.sections
          .map(
            (section) => {
              'sectionType': section.sectionType,
              'businessTypeId': section.businessTypeId,
              'businessTypeName': section.businessTypeName,
              'groupIndex': section.groupIndex,
              'rows': section.rows
                  .map(
                    (row) => {
                      'lineType': row.lineType,
                      'values': row.values,
                      'dataFilter': {
                        'businessTypeId': row.businessTypeId,
                        'section': row.section,
                      },
                      'taxMetadata': {
                        'taxType': row.taxType,
                        'rate': row.taxRate,
                      },
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'footerRows': value.footerRows
          .map(
            (row) => {
              'lineType': row.lineType,
              'values': row.values,
              'dataFilter': {
                'businessTypeId': row.businessTypeId,
                'section': row.section,
              },
              'taxMetadata': {'taxType': row.taxType, 'rate': row.taxRate},
            },
          )
          .toList(),
    };
  }
}
