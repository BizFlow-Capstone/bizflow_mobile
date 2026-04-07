import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/ai_draft_revenue_dto.dart';
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
        if (businessLocationId != null)
          'businessLocationId': businessLocationId,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      };

      final response = await _apiClient.get(
        ApiEndpoints.revenues,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        return RevenueResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
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

  Future<AiDraftRevenueResultDto> parseDraftRevenueFromAudio({
    required int locationId,
    required File audioFile,
  }) async {
    try {
      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        ApiEndpoints.aiDraftRevenue,
        fields: {'locationId': locationId.toString()},
        files: {'audio': audioFile},
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.message ?? 'Failed to parse draft revenue');
      }

      return AiDraftRevenueResultDto.fromJson(response.data!);
    } catch (e) {
      debugPrint('RevenueApiService.parseDraftRevenueFromAudio error: $e');
      rethrow;
    }
  }

  Future<RevenueDto> updateManualRevenue(
    int revenueId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateManualRevenue(revenueId.toString()),
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return RevenueDto.fromJson(data['data'] ?? data);
      }

      throw Exception(response.message ?? 'Failed to update revenue');
    } catch (e) {
      debugPrint('RevenueApiService.updateManualRevenue error: $e');
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
