import 'dart:io';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error_message_parser.dart';
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
    if (businessLocationId != null) queryParams['BusinessLocationId'] = businessLocationId.toString();
    if (costType != null) queryParams['CostType'] = costType;
    if (paymentMethod != null) queryParams['PaymentMethod'] = paymentMethod;
    if (fromDate != null) queryParams['FromDate'] = DateFormat('yyyy-MM-dd').format(fromDate);
    if (toDate != null) queryParams['ToDate'] = DateFormat('yyyy-MM-dd').format(toDate);

    final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.costs, queryParams: queryParams);
    if (response.data == null) throw Exception(ApiErrorMessageParser.genericMessage);
    return CostResponseDto.fromJson(response.data!);
  }

  Future<CostDto> createManualCost(Map<String, dynamic> body, {File? image}) async {
    final fields = <String, String>{
      'BusinessLocationId': body['businessLocationId']?.toString() ?? '0',
      'CostType': body['costType']?.toString() ?? '',
      'Amount': body['amount']?.toString() ?? '0',
      'CostDate': body['costDate']?.toString() ?? '',
      'Description': body['description']?.toString() ?? '',
      if (body['paymentMethod'] != null) 'PaymentMethod': body['paymentMethod'].toString(),
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

  Future<CostDto> updateManualCost(int costId, Map<String, dynamic> body, {File? image}) async {
    final fields = <String, String>{
      'Amount': body['amount']?.toString() ?? '0',
      'CostDate': body['costDate']?.toString() ?? '',
      'Description': body['description']?.toString() ?? '',
      if (body['paymentMethod'] != null) 'PaymentMethod': body['paymentMethod'].toString(),
      'RemoveDocument': (body['removeDocument'] ?? false).toString(),
    };

    final Map<String, File>? files = image != null ? {'image': image} : null;

    final response = await _apiClient.putMultipart<Map<String, dynamic>>(
      ApiEndpoints.updateManualCost(costId.toString()),
      fields: fields,
      files: files,
    );
    final responseData = response.data;
    if (responseData == null || !responseData.containsKey('data')) {
      throw Exception(ApiErrorMessageParser.genericMessage);
    }
    return CostDto.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<bool> deleteManualCost(int costId) async {
    final response = await _apiClient.delete(ApiEndpoints.deleteManualCost(costId.toString()));
    return response.statusCode == 200;
  }
}
