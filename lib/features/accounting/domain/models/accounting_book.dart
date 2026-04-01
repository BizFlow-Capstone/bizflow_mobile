import 'template_field_definition.dart';

class AccountingBook {
  final int bookId;
  final String bookCode;
  final String templateCode;
  final String? templateName;
  final String status; // 'ACTIVE', 'DRAFT', etc.
  final int periodId;
  final int groupNumber;
  final String? taxMethod;
  final DateTime createdAt;

  const AccountingBook({
    required this.bookId,
    required this.bookCode,
    required this.templateCode,
    this.templateName,
    required this.status,
    required this.periodId,
    required this.groupNumber,
    this.taxMethod,
    required this.createdAt,
  });

  /// Human-readable display name: "Sổ S1a — Sổ chi tiết bán hàng"
  String get displayName {
    final registryName =
        TemplateRegistry.getTemplate(templateCode)?.templateName;
    final name = templateName ?? registryName ?? templateCode;
    return 'Sổ $templateCode — $name';
  }

  factory AccountingBook.fromJson(Map<String, dynamic> json) {
    return AccountingBook(
      bookId: json['bookId'] as int? ?? 0,
      bookCode: json['bookCode'] as String? ?? '',
      templateCode: json['templateCode'] as String? ?? '',
      templateName: json['templateName'] as String?,
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
    'templateName': templateName,
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

// ─────────────────────── SECTIONS RESPONSE ───────────────────────

class BookColumnDto {
  final String fieldCode;
  final String label;
  final String fieldType;
  final String? exportColumn;

  const BookColumnDto({
    required this.fieldCode,
    required this.label,
    required this.fieldType,
    this.exportColumn,
  });

  factory BookColumnDto.fromJson(Map<String, dynamic> json) {
    return BookColumnDto(
      fieldCode: json['fieldCode'] as String? ?? '',
      label: json['label'] as String? ?? '',
      fieldType: json['fieldType'] as String? ?? 'text',
      exportColumn: json['exportColumn'] as String?,
    );
  }
}

class SectionRowDto {
  final String lineType;
  final Map<String, dynamic> values;
  final String? businessTypeId;
  final String? section;
  final String? taxType;
  final double? taxRate;

  const SectionRowDto({
    required this.lineType,
    required this.values,
    this.businessTypeId,
    this.section,
    this.taxType,
    this.taxRate,
  });

  factory SectionRowDto.fromJson(Map<String, dynamic> json) {
    final dataFilter = json['dataFilter'] as Map<String, dynamic>?;
    final taxMeta = json['taxMetadata'] as Map<String, dynamic>?;
    return SectionRowDto(
      lineType: json['lineType'] as String? ?? 'data',
      values: (json['values'] as Map<String, dynamic>?) ?? {},
      businessTypeId: dataFilter?['businessTypeId'] as String?,
      section: dataFilter?['section'] as String?,
      taxType: taxMeta?['taxType'] as String?,
      taxRate: (taxMeta?['rate'] as num?)?.toDouble(),
    );
  }
}

class BookSectionResponseDto {
  final String sectionType;
  final String? businessTypeId;
  final String? businessTypeName;
  final int groupIndex;
  final List<SectionRowDto> rows;

  const BookSectionResponseDto({
    required this.sectionType,
    this.businessTypeId,
    this.businessTypeName,
    required this.groupIndex,
    required this.rows,
  });

  factory BookSectionResponseDto.fromJson(Map<String, dynamic> json) {
    return BookSectionResponseDto(
      sectionType: json['sectionType'] as String? ?? '',
      businessTypeId: json['businessTypeId'] as String?,
      businessTypeName: json['businessTypeName'] as String?,
      groupIndex: json['groupIndex'] as int? ?? 0,
      rows: (json['rows'] as List<dynamic>?)
              ?.map((e) => SectionRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BookSectionsResponse {
  final int bookId;
  final String templateCode;
  final String templateName;
  final DateTime lastCalculatedAt;
  final List<BookColumnDto> columns;
  final List<BookSectionResponseDto> sections;
  final List<SectionRowDto> footerRows;

  const BookSectionsResponse({
    required this.bookId,
    required this.templateCode,
    required this.templateName,
    required this.lastCalculatedAt,
    required this.columns,
    required this.sections,
    required this.footerRows,
  });

  factory BookSectionsResponse.fromJson(Map<String, dynamic> json) {
    return BookSectionsResponse(
      bookId: json['bookId'] as int? ?? 0,
      templateCode: json['templateCode'] as String? ?? '',
      templateName: json['templateName'] as String? ?? '',
      lastCalculatedAt: json['lastCalculatedAt'] != null
          ? DateTime.parse(json['lastCalculatedAt'] as String)
          : DateTime.now(),
      columns: (json['columns'] as List<dynamic>?)
              ?.map(
                  (e) => BookColumnDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) =>
                  BookSectionResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      footerRows: (json['footerRows'] as List<dynamic>?)
              ?.map(
                  (e) => SectionRowDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
