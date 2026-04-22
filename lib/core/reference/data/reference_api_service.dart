import '../../network/api_client.dart';
import 'reference_item.dart';

class ReferenceApiService {
  final ApiClient _apiClient;

  ReferenceApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ReferenceItem>> _fetchList(String path) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/api/reference/$path');
    final responseData = response.data;
    if (responseData == null) return [];
    final data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((e) => ReferenceItem.fromDynamic(e)).toList();
  }

  Future<List<ReferenceItem>> getPaymentMethods() => _fetchList('payment-methods');
  Future<List<ReferenceItem>> getBusinessTypeStatuses() => _fetchList('business-type-statuses');
  Future<List<ReferenceItem>> getCostTypes() => _fetchList('cost-types');
  Future<List<ReferenceItem>> getGeneralLedgerReferenceTypes() => _fetchList('general-ledger-reference-types');
  Future<List<ReferenceItem>> getGeneralLedgerTransactionTypes() => _fetchList('general-ledger-transaction-types');
  Future<List<ReferenceItem>> getGeneralLedgerViewModes() => _fetchList('general-ledger-view-modes');
  Future<List<ReferenceItem>> getImportStatuses() => _fetchList('import-statuses');
  Future<List<ReferenceItem>> getImportTypes() => _fetchList('import-types');
  Future<List<ReferenceItem>> getMoneyChannelTypes() => _fetchList('money-channel-types');
  Future<List<ReferenceItem>> getOrderStatuses() => _fetchList('order-statuses');
  Future<List<ReferenceItem>> getProductStatuses() => _fetchList('product-statuses');
  Future<List<ReferenceItem>> getRevenueTypes() => _fetchList('revenue-types');
  Future<List<ReferenceItem>> getStockMovementTypes() => _fetchList('stock-movement-types');
  Future<List<ReferenceItem>> getStockMovementReferenceTypes() => _fetchList('stock-movement-reference-types');
}
