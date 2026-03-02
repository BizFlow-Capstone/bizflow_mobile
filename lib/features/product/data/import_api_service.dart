import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
    try {
      if (request.imagePath != null && request.imagePath!.isNotEmpty) {
        // Use multipart/form-data
        final Map<String, dynamic> dataMap = {
          'ImportType': request.importType,
          'BusinessLocationId': request.businessLocationId,
          'Supplier': request.supplier,
          'Note': request.note,
          'SaveAsDraft': request.saveAsDraft,
          if (request.receivedAt != null)
            'ReceivedAt': request.receivedAt!.toIso8601String(),
          // Assuming items can be sent as JSON string in multipart request
          if (request.items.isNotEmpty)
            'Items': jsonEncode(request.items.map((e) => e.toJson()).toList()),
        };

        final imageFile = File(request.imagePath!);
        if (imageFile.existsSync()) {
          final imageBytes = await imageFile.readAsBytes();
          dataMap['image'] = MultipartFile.fromBytes(
            imageBytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }

        final formData = FormData.fromMap(dataMap);

        final dio = Dio();
        final baseUrl = _apiClient.baseUrl;
        dio.options.headers = {'Accept-Language': 'en'};

        (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
            (HttpClient client) {
              client.badCertificateCallback = (cert, host, port) => true;
              return client;
            };

        final response = await dio.post(
          '$baseUrl${ApiEndpoints.createImport}',
          data: formData,
        );

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return response.data ?? {};
        } else {
          throw Exception(
            response.statusMessage ?? 'Failed to create import with image',
          );
        }
      } else {
        // Fallback to JSON request if no image
        final response = await _apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.createImport,
          body: request.toJson(),
        );

        return response.data ?? {};
      }
    } catch (e) {
      rethrow;
    }
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
