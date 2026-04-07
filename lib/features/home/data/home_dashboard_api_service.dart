import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/dashboard_summary_dto.dart';

class HomeDashboardApiService {
  final ApiClient _apiClient;

  HomeDashboardApiService({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<DashboardSummaryDto> getDashboardSummary({
    required String period,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? referenceDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'period': period,
        if (businessLocationId != null)
          'businessLocationId': businessLocationId,
        if (referenceDate != null) 'referenceDate': _toIsoDate(referenceDate),
        if (fromDate != null) 'fromDate': _toIsoDate(fromDate),
        if (toDate != null) 'toDate': _toIsoDate(toDate),
      };

      final response = await _apiClient.get(
        ApiEndpoints.dashboardSummary,
        queryParams: queryParams,
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.message ?? 'Failed to load dashboard summary');
      }

      final raw = response.data as Map<String, dynamic>;
      final payload = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;

      return DashboardSummaryDto.fromJson(payload);
    } catch (e) {
      debugPrint('HomeDashboardApiService.getDashboardSummary error: $e');
      rethrow;
    }
  }

  String _toIsoDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
