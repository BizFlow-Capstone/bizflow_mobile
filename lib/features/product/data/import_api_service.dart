import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'models/import_model.dart';

class ImportApiService {
  final ApiClient _apiClient;

  ImportApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getImports({
    String? status,
    String? importType,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['Status'] = status;
    if (importType != null) queryParams['ImportType'] = importType;
    if (businessLocationId != null)
      queryParams['BusinessLocationId'] = businessLocationId;
    if (fromDate != null) queryParams['FromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['ToDate'] = toDate.toIso8601String();
    if (pageNumber != null) queryParams['PageNumber'] = pageNumber;
    if (pageSize != null) queryParams['PageSize'] = pageSize;

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.imports,
      queryParams: queryParams,
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getImportDetail(int importId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.getImportDetail(importId.toString()),
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> createImport(CreateImportRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.createImport,
      body: request.toJson(),
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> updateImport(
    int importId,
    UpdateImportRequest request,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.updateImport(importId.toString()),
      body: request.toJson(),
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> confirmImport(
    int importId,
    ConfirmImportRequest request,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.confirmImport(importId.toString()),
      body: request.toJson(),
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> deleteImport(int importId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.deleteImport(importId.toString()),
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getImportTemplate() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.importTemplate,
    );

    return response.data ?? {};
  }
}
