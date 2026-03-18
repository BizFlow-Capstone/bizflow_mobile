import '../../domain/entities/debtor_entity.dart';

class DebtorListResult {
  final List<DebtorEntity> items;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const DebtorListResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory DebtorListResult.empty() {
    return const DebtorListResult(
      items: [],
      pageNumber: 1,
      pageSize: 20,
      totalPages: 1,
      totalCount: 0,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  factory DebtorListResult.fromApi(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return DebtorListResult.empty();
    }

    final itemsRaw = data['items'];
    final items = itemsRaw is List
      ? itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(DebtorEntity.fromMap)
          .toList()
      : <DebtorEntity>[];

    return DebtorListResult(
      items: items,
      pageNumber: (data['pageNumber'] as num?)?.toInt() ?? 1,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? 20,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? items.length,
      hasPreviousPage: data['hasPreviousPage'] == true,
      hasNextPage: data['hasNextPage'] == true,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'data': {
        'items': items.map((e) => e.toMap()).toList(),
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'totalPages': totalPages,
        'totalCount': totalCount,
        'hasPreviousPage': hasPreviousPage,
        'hasNextPage': hasNextPage,
      },
    };
  }

  factory DebtorListResult.fromCacheMap(Map<String, dynamic> json) {
    return DebtorListResult.fromApi(json);
  }
}
