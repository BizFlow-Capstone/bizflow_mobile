import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Lightweight service for checking if a document number already exists.
/// Used cross-module: orders, imports, revenues, costs.
class DocumentNumberService {
  final ApiClient _apiClient;

  DocumentNumberService({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Returns true if the given [documentNumber] already exists.
  /// Pass [excludeCostId] or [excludeRevenueId] to exclude a specific
  /// entity when editing (so it doesn't match itself).
  Future<bool> checkExists({
    required String documentNumber,
    int? excludeCostId,
    int? excludeRevenueId,
  }) async {
    if (documentNumber.trim().isEmpty) return false;

    final queryParams = <String, dynamic>{
      'DocumentNumber': documentNumber.trim(),
      if (excludeCostId != null) 'ExcludeCostId': excludeCostId,
      if (excludeRevenueId != null) 'ExcludeRevenueId': excludeRevenueId,
    };

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.documentNumberExists,
        queryParams: queryParams,
      );

      // Response shape: { "data": { "exists": true/false } }
      final data = response.data;
      if (data == null) return false;

      // Handle nested or flat response
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        return nested['exists'] == true;
      }
      return data['exists'] == true;
    } catch (_) {
      // If the check fails, don't block the user — treat as non-duplicate
      return false;
    }
  }
}
