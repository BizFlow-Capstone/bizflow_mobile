import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/dashboard_summary_dto.dart';
import 'models/home_ai_dto.dart';

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

  Future<HomeAiBundleDto> getAiBundle({required int locationId}) async {
    try {
      final forecastResponse = await _apiClient.get(
        ApiEndpoints.aiForecast,
        queryParams: {'locationId': locationId},
      );
      final reorderResponse = await _apiClient.get(
        ApiEndpoints.aiReorder,
        queryParams: {'locationId': locationId},
      );
      final insightsResponse = await _apiClient.get(
        ApiEndpoints.aiInsights,
        queryParams: {'locationId': locationId},
      );
      final anomaliesResponse = await _apiClient.get(
        ApiEndpoints.aiAnomalies,
        queryParams: {'locationId': locationId, 'acknowledged': false},
      );

      _throwWhenFailed(
        forecastResponse,
        fallback: 'Failed to load AI forecast',
      );
      _throwWhenFailed(reorderResponse, fallback: 'Failed to load AI reorder');
      _throwWhenFailed(
        insightsResponse,
        fallback: 'Failed to load AI insights',
      );
      _throwWhenFailed(
        anomaliesResponse,
        fallback: 'Failed to load AI anomalies',
      );

      final forecastPayload = _extractPayloadAsMap(forecastResponse.data);
      final forecastItems =
          (forecastPayload['forecasts'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(HomeAiForecastItemDto.fromJson)
              .toList();

      final reorderPayload = _extractPayloadAsList(reorderResponse.data);
      final reorderItems = reorderPayload
          .whereType<Map<String, dynamic>>()
          .map(HomeAiReorderItemDto.fromJson)
          .toList();

      final insightPayload = _extractPayloadAsList(insightsResponse.data);
      var insightItems = insightPayload
          .whereType<Map<String, dynamic>>()
          .map(HomeAiInsightItemDto.fromJson)
          .toList();

      insightItems = await _attachProductNames(insightItems);

      final anomalyPayload = _extractPayloadAsList(anomaliesResponse.data);
      final anomalyItems = anomalyPayload
          .whereType<Map<String, dynamic>>()
          .map(HomeAiAnomalyItemDto.fromJson)
          .toList();

      return HomeAiBundleDto(
        forecasts: forecastItems,
        reorders: reorderItems,
        insights: insightItems,
        anomalies: anomalyItems,
      );
    } catch (e) {
      debugPrint('HomeDashboardApiService.getAiBundle error: $e');
      rethrow;
    }
  }

  Future<void> acknowledgeAnomaly({
    required String anomalyId,
    required int locationId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.aiAcknowledgeAnomaly(anomalyId),
        queryParams: {'locationId': locationId},
      );

      _throwWhenFailed(response, fallback: 'Failed to acknowledge anomaly');
    } catch (e) {
      debugPrint('HomeDashboardApiService.acknowledgeAnomaly error: $e');
      rethrow;
    }
  }

  void _throwWhenFailed(
    ApiResponse<dynamic> response, {
    required String fallback,
  }) {
    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: response.message ?? fallback,
      data: response.data,
    );
  }

  Map<String, dynamic> _extractPayloadAsMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return raw;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractPayloadAsList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List<dynamic>) {
        return data;
      }
      final value = raw['value'];
      if (value is List<dynamic>) {
        return value;
      }
      return const <dynamic>[];
    }

    if (raw is List<dynamic>) {
      return raw;
    }

    return const <dynamic>[];
  }

  Future<List<HomeAiInsightItemDto>> _attachProductNames(
    List<HomeAiInsightItemDto> insights,
  ) async {
    if (insights.isEmpty) {
      return insights;
    }

    final uniqueProductIds = insights
        .map((item) => item.productId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final productNameById = <String, String>{};

    await Future.wait(
      uniqueProductIds.map((productId) async {
        try {
          final response = await _apiClient.get(
            ApiEndpoints.getProductDetail(productId),
          );
          if (!response.isSuccess || response.data == null) {
            return;
          }

          final payload = _extractPayloadAsMap(response.data);
          final name = payload['name']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            productNameById[productId] = name;
          }
        } catch (_) {
          // Keep insights usable even if one product detail call fails.
        }
      }),
    );

    return insights
        .map(
          (item) => item.copyWith(productName: productNameById[item.productId]),
        )
        .toList();
  }
}
