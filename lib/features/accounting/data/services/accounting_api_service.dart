import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/accounting_period.dart';
import '../../domain/models/accounting_book.dart';

class AccountingApiService {
  final ApiClient _apiClient;
  static String get _genericError => ApiErrorMessageParser.genericMessage;

  AccountingApiService({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// GET /api/locations/{locationId}/accounting/periods
  Future<List<AccountingPeriod>> listPeriods(String locationId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.accountingPeriods(locationId),
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final dataNode = data['data'];
        List<dynamic> list;
        if (dataNode is List) {
          list = dataNode;
        } else if (dataNode is Map) {
          list = (dataNode['items'] as List<dynamic>?) ?? [];
        } else {
          list = [];
        }
        return list
            .map((e) => AccountingPeriod.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.listPeriods error: $e');
      throw Exception(_genericError);
    }
  }

  /// POST /api/locations/{locationId}/accounting/periods
  Future<AccountingPeriod> createPeriod(
    String locationId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.accountingPeriods(locationId),
        body: body,
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return AccountingPeriod.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.createPeriod error: $e');
      throw Exception(_genericError);
    }
  }

  /// POST /api/locations/{locationId}/accounting/periods/custom
  Future<AccountingPeriod> createCustomPeriod(
    String locationId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.accountingPeriodsCustom(locationId),
        body: body,
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return AccountingPeriod.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.createCustomPeriod error: $e');
      throw Exception(_genericError);
    }
  }

  /// POST /api/locations/{locationId}/accounting/periods/opening-balance-suggestion
  Future<OpeningBalanceSuggestion> getOpeningBalanceSuggestion(
    String locationId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.accountingPeriodsOpeningBalanceSuggestion(locationId),
        body: body,
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return OpeningBalanceSuggestion.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.getOpeningBalanceSuggestion error: $e');
      throw Exception(_genericError);
    }
  }

  /// GET /api/locations/{locationId}/accounting/periods/{periodId}
  Future<AccountingPeriod> getPeriodDetail(
    String locationId,
    String periodId,
  ) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.accountingPeriodDetail(locationId, periodId),
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return AccountingPeriod.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.getPeriodDetail error: $e');
      throw Exception(_genericError);
    }
  }

  /// POST /api/locations/{locationId}/accounting/periods/{periodId}/finalize
  Future<AccountingPeriod> finalizePeriod(
    String locationId,
    String periodId,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.accountingPeriodFinalize(locationId, periodId),
        body: {},
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return AccountingPeriod.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      // Some backends just return success without data on finalize
      if (response.isSuccess) {
        // Return a placeholder to trigger refresh
        throw Exception('__refresh_required__');
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      if (e.toString().contains('__refresh_required__')) rethrow;
      debugPrint('AccountingApiService.finalizePeriod error: $e');
      throw Exception(_genericError);
    }
  }

  /// POST /api/locations/{locationId}/accounting/periods/{periodId}/reopen
  Future<void> reopenPeriod(
    String locationId,
    String periodId,
    String reason,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.accountingPeriodReopen(locationId, periodId),
        body: {'reason': reason},
      );
      if (!response.isSuccess) {
        throw Exception(_genericError);
      }
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.reopenPeriod error: $e');
      throw Exception(_genericError);
    }
  }

  /// GET /api/locations/{locationId}/accounting/periods/{periodId}/audit-logs
  Future<List<AccountingPeriodAuditLog>> getAuditLogs(
    String locationId,
    String periodId,
  ) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.accountingPeriodAuditLogs(locationId, periodId),
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final dataNode = data['data'];
        List<dynamic> list;
        if (dataNode is List) {
          list = dataNode;
        } else if (dataNode is Map) {
          list = (dataNode['items'] as List<dynamic>?) ?? [];
        } else {
          list = [];
        }
        return list
            .map(
              (e) => AccountingPeriodAuditLog.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.getAuditLogs error: $e');
      throw Exception(_genericError);
    }
  }

  /// POST /api/locations/{locationId}/accounting/books
  /// Create accounting books from templateCodes for a period
  /// Request: { periodId, groupNumber, taxMethod, templateCodes[] }
  Future<CreateBooksResponse> createBooksForPeriod(
    String locationId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createAccountingBooks(locationId),
        body: body,
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return CreateBooksResponse.fromJson(data);
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.createBooksForPeriod error: $e');
      throw Exception(_genericError);
    }
  }

  /// GET /api/locations/{locationId}/accounting/books
  /// List all accounting books for a location
  Future<List<AccountingBook>> listBooks(
    String locationId, {
    String? periodId,
  }) async {
    try {
      String endpoint = ApiEndpoints.accountingBooks(locationId);
      if (periodId != null) {
        endpoint += '?periodId=$periodId';
      }
      final response = await _apiClient.get(endpoint);
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final dataNode = data['data'];
        List<dynamic> list;
        if (dataNode is List) {
          list = dataNode;
        } else if (dataNode is Map) {
          list = (dataNode['items'] as List<dynamic>?) ?? [];
        } else {
          list = [];
        }
        return list
            .map((e) => AccountingBook.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.listBooks error: $e');
      throw Exception(_genericError);
    }
  }

  /// GET /api/locations/{locationId}/accounting/books/{bookId}/rows
  /// Get book rows for rendering in UI / export
  Future<BookRowsResponse> getBookRows(
    String locationId,
    String bookId, {
    String? cursor,
    int batchSize = 200,
  }) async {
    try {
      String endpoint = ApiEndpoints.accountingBookRows(locationId, bookId);
      final params = <String>[];
      if (cursor != null) params.add('cursor=$cursor');
      if (batchSize != 200) params.add('batchSize=$batchSize');
      if (params.isNotEmpty) {
        endpoint += '?${params.join("&")}';
      }

      final response = await _apiClient.get(endpoint);
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return BookRowsResponse.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.getBookRows error: $e');
      throw Exception(_genericError);
    }
  }

  /// GET /api/locations/{locationId}/accounting/books/{bookId}/sections
  /// Get structured sections data for template-aware rendering
  Future<BookSectionsResponse> getBookSections(
    String locationId,
    String bookId,
  ) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.accountingBookSections(locationId, bookId),
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return BookSectionsResponse.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      throw Exception(_genericError);
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.getBookSections error: $e');
      throw Exception(_genericError);
    }
  }

  /// DELETE /api/locations/{locationId}/accounting/books/{bookId}
  Future<void> deleteBook(String locationId, String bookId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.accountingBooksDetail(locationId, bookId),
      );
      if (!response.isSuccess) {
        throw Exception(_genericError);
      }
    } on ApiException catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    } catch (e) {
      debugPrint('AccountingApiService.deleteBook error: $e');
      throw Exception(_genericError);
    }
  }
}
