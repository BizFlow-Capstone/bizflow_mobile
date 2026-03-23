import '../../network/api_client.dart';

class ReferenceApiService {
  final ApiClient _apiClient;

  ReferenceApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<String>> _fetchList(String path) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/api/reference/$path');
    final responseData = response.data;
    if (responseData == null) return [];
    final data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<List<String>> getPaymentMethods() => _fetchList('payment-methods');
  Future<List<String>> getBusinessTypeStatuses() => _fetchList('business-type-statuses');
  Future<List<String>> getCostTypes() => _fetchList('cost-types');
  Future<List<String>> getGeneralLedgerReferenceTypes() => _fetchList('general-ledger-reference-types');
  Future<List<String>> getGeneralLedgerTransactionTypes() => _fetchList('general-ledger-transaction-types');
  Future<List<String>> getGeneralLedgerViewModes() => _fetchList('general-ledger-view-modes');
  Future<List<String>> getImportStatuses() => _fetchList('import-statuses');
  Future<List<String>> getImportTypes() => _fetchList('import-types');
  Future<List<String>> getMoneyChannelTypes() => _fetchList('money-channel-types');
  Future<List<String>> getOrderStatuses() => _fetchList('order-statuses');
  Future<List<String>> getProductStatuses() => _fetchList('product-statuses');
  Future<List<String>> getRevenueTypes() => _fetchList('revenue-types');
  Future<List<String>> getStockMovementTypes() => _fetchList('stock-movement-types');
  Future<List<String>> getStockMovementReferenceTypes() => _fetchList('stock-movement-reference-types');
}
