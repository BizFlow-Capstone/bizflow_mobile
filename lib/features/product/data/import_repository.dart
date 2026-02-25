import 'import_api_service.dart';
import 'models/import_model.dart';

class ImportRepository {
  final ImportApiService _apiService;

  ImportRepository(this._apiService);

  Future<Map<String, dynamic>> getImports({
    String? status,
    String? importType,
    int? businessLocationId,
    DateTime? fromDate,
    DateTime? toDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      return await _apiService.getImports(
        status: status,
        importType: importType,
        businessLocationId: businessLocationId,
        fromDate: fromDate,
        toDate: toDate,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getImportDetail(int importId) async {
    try {
      return await _apiService.getImportDetail(importId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createImport(CreateImportRequest request) async {
    try {
      return await _apiService.createImport(request);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateImport(
    int importId,
    UpdateImportRequest request,
  ) async {
    try {
      return await _apiService.updateImport(importId, request);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> confirmImport(
    int importId,
    ConfirmImportRequest request,
  ) async {
    try {
      return await _apiService.confirmImport(importId, request);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteImport(int importId) async {
    try {
      return await _apiService.deleteImport(importId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getImportTemplate() async {
    try {
      return await _apiService.getImportTemplate();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
