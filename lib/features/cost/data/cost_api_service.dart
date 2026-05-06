import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error_message_parser.dart';
import 'models/ai_draft_cost_dto.dart';
import 'models/cost_dto.dart';

class CostApiService {
  final ApiClient _apiClient;

  CostApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<CostResponseDto> getCosts({
    required int pageNumber,
    required int pageSize,
    int? businessLocationId,
    String? costType,
    String? paymentMethod,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };
    if (businessLocationId != null) {
      queryParams['BusinessLocationId'] = businessLocationId.toString();
    }
    if (costType != null) queryParams['CostType'] = costType;
    if (paymentMethod != null) queryParams['PaymentMethod'] = paymentMethod;
    if (fromDate != null) {
      queryParams['FromDate'] = DateFormat('yyyy-MM-dd').format(fromDate);
    }
    if (toDate != null) {
      queryParams['ToDate'] = DateFormat('yyyy-MM-dd').format(toDate);
    }

    debugPrint('[CostApiService] GET ${ApiEndpoints.costs} query=$queryParams');

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.costs,
      queryParams: queryParams,
    );
    if (response.data == null) {
      debugPrint('[CostApiService] response data is null');
      throw Exception(ApiErrorMessageParser.genericMessage);
    }

    final dto = CostResponseDto.fromJson(response.data!);
    debugPrint(
      '[CostApiService] response items=${dto.items.length} total=${dto.totalCount}',
    );
    return dto;
  }

  Future<CostDto> createManualCost(
    Map<String, dynamic> body, {
    File? image,
  }) async {
    final fields = <String, String>{
      'BusinessLocationId': body['businessLocationId']?.toString() ?? '0',
      'CostType': body['costType']?.toString() ?? '',
      'Amount': body['amount']?.toString() ?? '0',
      'CostDate': body['costDate']?.toString() ?? '',
      if (body['documentDate'] != null)
        'DocumentDate': body['documentDate'].toString(),
      if (body['documentNumber'] != null)
        'DocumentNumber': body['documentNumber'].toString(),
      'Description': body['description']?.toString() ?? '',
      if (body['paymentMethod'] != null)
        'PaymentMethod': body['paymentMethod'].toString(),
    };

    final Map<String, File>? files = image != null ? {'image': image} : null;

    final response = await _apiClient.postMultipart<Map<String, dynamic>>(
      ApiEndpoints.createManualCost,
      fields: fields,
      files: files,
    );
    final responseData = response.data;
    if (responseData == null || !responseData.containsKey('data')) {
      throw Exception(ApiErrorMessageParser.genericMessage);
    }
    return CostDto.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<CostDto> updateManualCost(
    int costId,
    String? idempotencyKey,
    Map<String, dynamic> body, {
    File? image,
  }) async {
    final trimmedIdempotencyKey = idempotencyKey?.trim();
    final fields = <String, String>{
      'Amount': body['amount']?.toString() ?? '0',
      'CostDate': body['costDate']?.toString() ?? '',
      if (body['documentDate'] != null)
        'DocumentDate': body['documentDate'].toString(),
      if (body['documentNumber'] != null)
        'DocumentNumber': body['documentNumber'].toString(),
      'Description': body['description']?.toString() ?? '',
      if (body['paymentMethod'] != null)
        'PaymentMethod': body['paymentMethod'].toString(),
      'RemoveDocument': (body['removeDocument'] ?? false).toString(),
      if (trimmedIdempotencyKey != null && trimmedIdempotencyKey.isNotEmpty)
        'IdempotencyKey': trimmedIdempotencyKey,
    };

    final Map<String, File>? files = image != null ? {'image': image} : null;

    final response = await _apiClient.putMultipart<Map<String, dynamic>>(
      ApiEndpoints.updateManualCost(costId.toString()),
      fields: fields,
      files: files,
      headers: {
        if (trimmedIdempotencyKey != null && trimmedIdempotencyKey.isNotEmpty)
          'Idempotency-Key': trimmedIdempotencyKey,
      },
    );

    // Persist a lightweight log for debug on devices where console isn't available.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/update_debug.log');
      final logEntry = {
        'time': DateTime.now().toIso8601String(),
        'endpoint': ApiEndpoints.updateManualCost(costId.toString()),
        'method': 'PUT',
        'fields': fields.keys.toList(),
        'hasImage': image != null,
        'idempotencyKey': trimmedIdempotencyKey ?? '',
      };
      await logFile.writeAsString(
        '${logEntry.toString()}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // best-effort logging only
    }
    final responseData = response.data;
    if (responseData == null || !responseData.containsKey('data')) {
      throw Exception(ApiErrorMessageParser.genericMessage);
    }
    return CostDto.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<bool> deleteManualCost(int costId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.deleteManualCost(costId.toString()),
    );
    return response.statusCode == 200;
  }

  Future<AiDraftCostResultDto> parseDraftCostFromAudio({
    required int locationId,
    required File audioFile,
  }) async {
    final response = await _apiClient.postMultipart<Map<String, dynamic>>(
      ApiEndpoints.aiDraftCost,
      fields: {'locationId': locationId.toString()},
      files: {'audio': audioFile},
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message ?? ApiErrorMessageParser.genericMessage);
    }

    return AiDraftCostResultDto.fromJson(response.data!);
  }
}
