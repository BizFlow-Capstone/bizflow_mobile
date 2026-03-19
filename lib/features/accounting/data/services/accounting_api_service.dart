import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/accounting_period.dart';

class AccountingApiService {
  final ApiClient _apiClient;

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
      throw Exception(response.message ?? 'Failed to load periods');
    } on ApiException catch (e) {
      throw Exception('API Error ${e.statusCode}: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.listPeriods error: $e');
      rethrow;
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
      throw Exception(response.message ?? 'Failed to create period');
    } on ApiException catch (e) {
      if (e.statusCode == 409) throw Exception('period_already_exists');
      if (e.statusCode == 400) throw Exception('period_validation_error: ${e.message}');
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.createPeriod error: $e');
      rethrow;
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
      throw Exception(response.message ?? 'Failed to create custom period');
    } on ApiException catch (e) {
      if (e.statusCode == 400) throw Exception('period_validation_error: ${e.message}');
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.createCustomPeriod error: $e');
      rethrow;
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
      throw Exception(response.message ?? 'Failed to get suggestion');
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.getOpeningBalanceSuggestion error: $e');
      rethrow;
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
      throw Exception(response.message ?? 'Period not found');
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw Exception('period_not_found');
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.getPeriodDetail error: $e');
      rethrow;
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
      throw Exception(response.message ?? 'Failed to finalize');
    } on ApiException catch (e) {
      final data = e.data;
      final messageCode = data is Map<String, dynamic>
          ? data['messageCode']?.toString()
          : null;

      if (e.statusCode == 400) {
        if (messageCode == 'PERIOD_NO_ACTIVE_BOOK' ||
            messageCode == 'PERIOD_NO_BOOKS' ||
            e.message.toLowerCase().contains('active accounting book') ||
            e.message.toLowerCase().contains('ít nhất 1 sổ')) {
          throw Exception('period_no_books');
        }

        if (messageCode == 'PERIOD_ALREADY_FINALIZED' ||
            messageCode == 'PERIOD_CANNOT_FINALIZE') {
          throw Exception('period_already_finalized');
        }
      }

      throw Exception('API Error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('__refresh_required__')) rethrow;
      debugPrint('AccountingApiService.finalizePeriod error: $e');
      rethrow;
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
        throw Exception(response.message ?? 'Failed to reopen period');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 400) throw Exception('reopen_reason_required');
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.reopenPeriod error: $e');
      rethrow;
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
      throw Exception(response.message ?? 'Failed to load audit logs');
    } on ApiException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      debugPrint('AccountingApiService.getAuditLogs error: $e');
      rethrow;
    }
  }
}
