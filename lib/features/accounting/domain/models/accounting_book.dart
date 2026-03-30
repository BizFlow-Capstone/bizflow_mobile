class AccountingBook {
  final int bookId;
  final String bookCode;
  final String templateCode;
  final String status; // 'ACTIVE', 'DRAFT', etc.
  final int periodId;
  final int groupNumber;
  final String? taxMethod;
  final DateTime createdAt;

  const AccountingBook({
    required this.bookId,
    required this.bookCode,
    required this.templateCode,
    required this.status,
    required this.periodId,
    required this.groupNumber,
    this.taxMethod,
    required this.createdAt,
  });

  factory AccountingBook.fromJson(Map<String, dynamic> json) {
    return AccountingBook(
      bookId: json['bookId'] as int? ?? 0,
      bookCode: json['bookCode'] as String? ?? '',
      templateCode: json['templateCode'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      periodId: json['periodId'] as int? ?? 0,
      groupNumber: json['groupNumber'] as int? ?? 0,
      taxMethod: json['taxMethod'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'bookCode': bookCode,
    'templateCode': templateCode,
    'status': status,
    'periodId': periodId,
    'groupNumber': groupNumber,
    'taxMethod': taxMethod,
    'createdAt': createdAt.toIso8601String(),
  };
}

class CreateBooksResponse {
  final String message;
  final bool success;
  final List<AccountingBook> createdBooks;

  const CreateBooksResponse({
    required this.message,
    required this.success,
    required this.createdBooks,
  });

  factory CreateBooksResponse.fromJson(Map<String, dynamic> json) {
    List<AccountingBook> books = [];
    final data = json['data'];
    if (data != null) {
      if (data is List) {
        books = List<AccountingBook>.from(
          data.map((e) => AccountingBook.fromJson(e as Map<String, dynamic>)),
        );
      } else if (data is Map && data['createdBooks'] is List) {
        books = List<AccountingBook>.from(
          (data['createdBooks'] as List).map(
            (e) => AccountingBook.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
    }
    return CreateBooksResponse(
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      createdBooks: books,
    );
  }
}

class BookRowsResponse {
  final List<Map<String, dynamic>> rows; // Each row is dynamic data
  final bool hasMore;
  final String? nextCursor;
  final int loadedCount;
  final int? totalEstimated;

  const BookRowsResponse({
    required this.rows,
    required this.hasMore,
    this.nextCursor,
    required this.loadedCount,
    this.totalEstimated,
  });

  factory BookRowsResponse.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List<dynamic>?)
            ?.map((e) => (e as Map<String, dynamic>))
            .toList() ??
        [];
    return BookRowsResponse(
      rows: rows,
      hasMore: json['hasMore'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
      loadedCount: json['loadedCount'] as int? ?? 0,
      totalEstimated: json['totalEstimated'] as int?,
    );
  }
}
