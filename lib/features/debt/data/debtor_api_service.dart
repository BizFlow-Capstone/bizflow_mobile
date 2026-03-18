import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class DebtorApiService {
  final ApiClient _apiClient;

  DebtorApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getDebtors({
    List<int>? businessLocationIds,
    String? search,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'PageNumber': pageNumber,
      'PageSize': pageSize,
    };

    if (businessLocationIds != null && businessLocationIds.isNotEmpty) {
      queryParams['BusinessLocationIds'] = businessLocationIds;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['Search'] = search.trim();
    }
    if (isActive != null) {
      queryParams['IsActive'] = isActive;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.debtors,
      queryParams: queryParams,
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDebtorDetail(int debtorId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.debtorDetail(debtorId.toString()),
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createDebtor({
    required int businessLocationId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    double? creditLimit,
  }) async {
    final body = <String, dynamic>{
      'businessLocationId': businessLocationId,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'creditLimit': creditLimit,
    }..removeWhere((key, value) => value == null);

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.debtors,
      body: body,
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateDebtor({
    required int debtorId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    double? creditLimit,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'creditLimit': creditLimit,
    }..removeWhere((key, value) => value == null);

    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.debtorDetail(debtorId.toString()),
      body: body,
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> recordDebtAdjustment({
    required int debtorId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
    }..removeWhere((key, value) => value == null);

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.debtorPayments(debtorId.toString()),
      body: body,
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDebtPaymentHistory(int debtorId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.debtorPayments(debtorId.toString()),
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateDebtorStatus({
    required int debtorId,
    required bool isActive,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.debtorStatus(debtorId.toString()),
      body: {'isActive': isActive},
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getActiveDebtorsByLocation(
    int locationId,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.activeDebtorsByLocation(locationId.toString()),
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> deleteDebtor({
    required int debtorId,
    bool force = false,
  }) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.debtorDetail(debtorId.toString()),
      queryParams: {'force': force},
    );

    return response.data ?? <String, dynamic>{};
  }
}
