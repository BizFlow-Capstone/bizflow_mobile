import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/network/api_endpoints.dart';
import 'package:intl/intl.dart';

class GLApiService {
  final ApiClient _apiClient;

  GLApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getGLEntries({
    required int businessLocationId,
    required int pageNumber,
    required int pageSize,
    List<String>? transactionTypes,
    List<String>? referenceTypes,
    List<String>? moneyChannels,
    DateTime? fromDate,
    DateTime? toDate,
    String viewMode = 'audit',
  }) async {
    // Format dates to 'yyyy-MM-dd' if provided
    String? formattedFromDate;
    String? formattedToDate;
    if (fromDate != null) {
      formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
    }
    if (toDate != null) {
      formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
    }

    final queryParams = <String, dynamic>{
      'businessLocationId': businessLocationId.toString(),
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
      'viewMode': viewMode,
    };

    if (transactionTypes != null && transactionTypes.isNotEmpty) {
      queryParams['transactionTypes'] = transactionTypes;
    }
    if (referenceTypes != null && referenceTypes.isNotEmpty) {
      queryParams['referenceTypes'] = referenceTypes;
    }
    if (moneyChannels != null && moneyChannels.isNotEmpty) {
      queryParams['moneyChannels'] = moneyChannels;
    }
    if (formattedFromDate != null) {
      queryParams['fromDate'] = formattedFromDate;
    }
    if (formattedToDate != null) {
      queryParams['toDate'] = formattedToDate;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.glEntries,
      queryParams: queryParams,
    );

    final responseData = response.data;
    if (responseData == null) {
      throw Exception(ApiErrorMessageParser.genericMessage);
    }
    return responseData['data'] as Map<String, dynamic>;
  }
}
