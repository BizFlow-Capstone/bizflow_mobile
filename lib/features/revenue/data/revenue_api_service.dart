import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/revenue_dto.dart';

class RevenueApiService {
  final ApiClient _apiClient;

  RevenueApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<RevenueResponseDto> getRevenues({
    int pageNumber = 1,
    int pageSize = 20,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (businessLocationId != null) 'businessLocationId': businessLocationId,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      };

      final response = await _apiClient.get(
        ApiEndpoints.revenues,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        return RevenueResponseDto.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.message ?? 'Failed to load revenues');
      }
    } catch (e) {
      debugPrint('RevenueApiService.getRevenues error: $e');
      rethrow;
    }
  }

  Future<RevenueDto> createManualRevenue(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createManualRevenue,
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return RevenueDto.fromJson(data['data'] ?? data);
      } else {
        throw Exception(response.message ?? 'Failed to create revenue');
      }
    } catch (e) {
      debugPrint('RevenueApiService.createManualRevenue error: $e');
      rethrow;
    }
  }

  Future<bool> deleteManualRevenue(int revenueId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteManualRevenue(revenueId.toString()),
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to delete revenue');
      }
    } catch (e) {
      debugPrint('RevenueApiService.deleteManualRevenue error: $e');
      rethrow;
    }
  }
}
