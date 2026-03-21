import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/utils/date_formatter.dart';
import 'models/import_model.dart';

class ImportApiService {
  final ApiClient _apiClient;

  ImportApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<String?> _getAuthToken() async {
    return SecureStorage().read(key: SecureStorageKeys.accessToken);
  }

  Future<Map<String, dynamic>> _postMultipart(
    String endpoint,
    Map<String, dynamic> dataMap,
  ) async {
    final formData = FormData.fromMap(dataMap);

    final dio = Dio();
    final baseUrl = _apiClient.baseUrl;
    final token = await _getAuthToken();

    dio.options.headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    final response = await dio.post('$baseUrl$endpoint', data: formData);
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return (response.data as Map<String, dynamic>?) ?? {};
    }
    throw Exception(response.statusMessage ?? 'Multipart request failed');
  }

  Future<Map<String, dynamic>> _putMultipart(
    String endpoint,
    Map<String, dynamic> dataMap,
  ) async {
    final formData = FormData.fromMap(dataMap);

    final dio = Dio();
    final baseUrl = _apiClient.baseUrl;
    final token = await _getAuthToken();

    dio.options.headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    final response = await dio.put('$baseUrl$endpoint', data: formData);
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return (response.data as Map<String, dynamic>?) ?? {};
    }
    throw Exception(response.statusMessage ?? 'Multipart request failed');
  }

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
    if (businessLocationId != null) {
      queryParams['BusinessLocationId'] = businessLocationId;
    }
    if (fromDate != null) {
      queryParams['FromDate'] = DateFormatter.toApiUtcIsoString(fromDate);
    }
    if (toDate != null) {
      queryParams['ToDate'] = DateFormatter.toApiUtcIsoString(toDate);
    }
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
      final Map<String, dynamic> dataMap = {
        'ImportType': request.importType,
        'BusinessLocationId': request.businessLocationId,
        'Supplier': request.supplier,
        'Note': request.note,
        'SaveAsDraft': request.saveAsDraft,
        if (request.receivedAt != null)
          'ReceivedAt': DateFormatter.toApiUtcIsoString(request.receivedAt!),
        'Items': jsonEncode(request.items.map((e) => e.toJson()).toList()),
      };

      if (request.imagePath != null && request.imagePath!.isNotEmpty) {
        final imageFile = File(request.imagePath!);
        if (imageFile.existsSync()) {
          final imageBytes = await imageFile.readAsBytes();
          dataMap['image'] = MultipartFile.fromBytes(
            imageBytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      return await _postMultipart(ApiEndpoints.createImport, dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateImport(
    int importId,
    UpdateImportRequest request,
  ) async {
    final Map<String, dynamic> dataMap = {
      'ImportType': request.importType,
      'Supplier': request.supplier,
      'Note': request.note,
      'RemoveImage': request.removeImage,
      if (request.receivedAt != null)
        'ReceivedAt': DateFormatter.toApiUtcIsoString(request.receivedAt!),
      'Items': jsonEncode(request.items.map((e) => e.toJson()).toList()),
    };

    if (request.imagePath != null && request.imagePath!.isNotEmpty) {
      final imageFile = File(request.imagePath!);
      if (imageFile.existsSync()) {
        final imageBytes = await imageFile.readAsBytes();
        dataMap['image'] = MultipartFile.fromBytes(
          imageBytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
    }

    return await _putMultipart(
      ApiEndpoints.updateImport(importId.toString()),
      dataMap,
    );
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
