import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/ocr_purchase_invoice_dto.dart';
import '../../../../shared/utils/date_formatter.dart';
import 'models/import_model.dart';

class ImportApiService {
  final ApiClient _apiClient;

  ImportApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Map<String, dynamic> _buildImportItemPayload(ImportItemModel item) {
    return {
      'ProductId': item.productId,
      'Quantity': item.quantity,
      'CostPrice': item.costPrice,
    };
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

    return (response.data?['data'] as Map<String, dynamic>?) ??
        response.data ??
        {};
  }

  Future<Map<String, dynamic>> getImportDetail(int importId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.getImportDetail(importId.toString()),
    );

    return (response.data?['data'] as Map<String, dynamic>?) ??
        response.data ??
        {};
  }

  Future<Map<String, dynamic>> createImport(CreateImportRequest request) async {
    try {
      final Map<String, String> fields = {
        'ImportType': request.importType,
        'BusinessLocationId': request.businessLocationId.toString(),
        'Supplier': request.supplier,
        'Note': request.note,
        'SaveAsDraft': request.saveAsDraft.toString(),
        if (request.documentDate != null)
          'DocumentDate': DateFormatter.toApiDateOnly(request.documentDate!),
        if (request.documentNumber != null &&
            request.documentNumber!.isNotEmpty)
          'DocumentNumber': request.documentNumber!,
        if (request.receivedAt != null)
          'ReceivedAt': DateFormatter.toApiUtcIsoString(request.receivedAt!),
        'Items': jsonEncode(
          request.items.map(_buildImportItemPayload).toList(),
        ),
        if (request.paymentMethod != null &&
            request.paymentMethod!.isNotEmpty)
          'PaymentMethod': request.paymentMethod!,
      };

      final Map<String, File> files = {};
      if (request.imagePath != null && request.imagePath!.isNotEmpty) {
        final imageFile = File(request.imagePath!);
        if (imageFile.existsSync()) {
          files['image'] = imageFile;
        }
      }

      final response = await _apiClient.postMultipart(
        ApiEndpoints.createImport,
        fields: fields,
        files: files,
      );

      if (response.isSuccess) {
        return response.data ?? {};
      }
      throw Exception(response.message ?? 'Create import failed');
    } catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    }
  }

  Future<Map<String, dynamic>> updateImport(
    int importId,
    UpdateImportRequest request,
  ) async {
    try {
      final Map<String, String> fields = {
        'ImportType': request.importType,
        'Supplier': request.supplier,
        'Note': request.note,
        'RemoveImage': request.removeImage.toString(),
        if (request.idempotencyKey != null &&
            request.idempotencyKey!.isNotEmpty)
          'IdempotencyKey': request.idempotencyKey!,
        if (request.documentDate != null)
          'DocumentDate': DateFormatter.toApiDateOnly(request.documentDate!),
        if (request.documentNumber != null &&
            request.documentNumber!.isNotEmpty)
          'DocumentNumber': request.documentNumber!,
        if (request.receivedAt != null)
          'ReceivedAt': DateFormatter.toApiUtcIsoString(request.receivedAt!),
        'Items': jsonEncode(
          request.items.map(_buildImportItemPayload).toList(),
        ),
        if (request.paymentMethod != null &&
            request.paymentMethod!.isNotEmpty)
          'PaymentMethod': request.paymentMethod!,
      };

      final Map<String, File> files = {};
      if (request.imagePath != null && request.imagePath!.isNotEmpty) {
        final imageFile = File(request.imagePath!);
        if (imageFile.existsSync()) {
          files['image'] = imageFile;
        }
      }

      final response = await _apiClient.putMultipart(
        ApiEndpoints.updateImport(importId.toString()),
        fields: fields,
        files: files,
      );

      if (response.isSuccess) {
        return response.data ?? {};
      }
      throw Exception(response.message ?? 'Update import failed');
    } catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    }
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

  Future<OcrPurchaseInvoiceResultDto> ocrPurchaseInvoice({
    required int locationId,
    required File imageFile,
  }) async {
    try {
      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        ApiEndpoints.aiOcrPurchaseInvoice,
        fields: {'locationId': locationId.toString()},
        files: {'image': imageFile},
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.message ?? 'OCR purchase invoice failed');
      }

      return OcrPurchaseInvoiceResultDto.fromJson(response.data!);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception(ApiErrorMessageParser.parse(e));
    }
  }
}
