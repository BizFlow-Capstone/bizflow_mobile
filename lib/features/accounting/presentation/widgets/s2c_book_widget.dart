import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Widget hiển thị Sổ chi tiết doanh thu, chi phí mẫu S2c-HKD (TT152)
/// Hiển thị bảng tổng hợp cố định theo mẫu TT152 cho S2c.
class S2cBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S2cBookWidget({
    super.key,
    required this.sections,
    this.dataRows = const [],
  });

  static const _soTienAliases = [
    'Amount',
    'so_tien',
    'revenue',
    'cost',
    'finalAmount',
    'totalAmount',
    'amount',
    'planPrice',
  ];
  static const _soHieuAliases = [
    'so_hieu',
    'documentNumber',
    'DocumentNumber',
    'voucherNo',
    'voucher_no',
    'so_chung_tu',
    'documentNo',
    'DocumentNo',
  ];
  static const _costHints = [
    'CostType',
    'costType',
    'CostDate',
    'costDate',
    'CostId',
    'costId',
  ];
  static const _dateAliases = [
    'costDate',
    'CostDate',
    'ngay_thang',
    'receivedAt',
    'createdAt',
    'updatedAt',
    'documentDate',
    'date',
  ];
  static const _descAliases = [
    'description',
    'Description',
    'note',
    'dien_giai',
    'planName',
    'businessLocationName',
  ];

  @override
  Widget build(BuildContext context) {
    final summary = _resolveSummary();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildTable(context, summary),
          _buildBreakdowns(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Mẫu số S2c-HKD',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SỔ CHI TIẾT DOANH THU BÁN HÀNG HÓA, DỊCH VỤ',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, _S2cSummaryData summary) {
    final tableRows = <DataRow>[];

    tableRows.add(
      _buildSummaryRow(
        code: '',
        '1. Doanh thu bán hàng hóa, dịch vụ',
        _fmtAmount(summary.revenueTotal),
        emphasized: true,
      ),
    );
    tableRows.addAll(
      summary.revenueEntries.map(
        (entry) => _buildSummaryRow(
          code: entry.code,
          date: entry.date,
          entry.note,
          _fmtAmount(entry.amount),
          explanation: entry.explanation,
        ),
      ),
    );

    tableRows.add(
      _buildSummaryRow(
        code: '',
        '2. Chi phí hợp lý',
        _fmtAmount(summary.costTotal),
        emphasized: true,
      ),
    );
    tableRows.addAll(
      summary.costEntries.map(
        (entry) => _buildSummaryRow(
          code: entry.code,
          date: entry.date,
          entry.note,
          _fmtAmount(entry.amount),
          explanation: entry.explanation,
        ),
      ),
    );

    tableRows.add(
      _buildSummaryRow(
        code: '',
        '3. Chênh lệch {(3) = (1) - (2)}',
        _fmtAmount(summary.difference),
        emphasized: true,
      ),
    );
    tableRows.add(
      _buildSummaryRow(
        code: '',
        '4. Thuế TNCN phải nộp',
        _fmtAmount(summary.pitTax),
        emphasized: true,
        taxLike: true,
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
        columnSpacing: 20,
        columns: _buildColumns(),
        rows: tableRows,
      ),
    );
  }

  List<BookColumnDto> _effectiveColumns() {
    if (sections.columns.isNotEmpty) {
      return sections.columns;
    }
    return const [
      BookColumnDto(fieldCode: 'so_hieu', label: 'Số hiệu', fieldType: 'text'),
      BookColumnDto(
        fieldCode: 'ngay_thang',
        label: 'Ngày, tháng',
        fieldType: 'date',
      ),
      BookColumnDto(
        fieldCode: 'dien_giai',
        label: 'Diễn giải',
        fieldType: 'text',
      ),
      BookColumnDto(fieldCode: 'so_tien', label: 'Số tiền', fieldType: 'money'),
    ];
  }

  List<DataColumn> _buildColumns() {
    return _effectiveColumns().map((column) {
      return DataColumn(
        label: Text(column.label, style: _headerStyle()),
        numeric: _isNumericColumn(column),
      );
    }).toList();
  }

  Widget _buildBreakdowns(BuildContext context) {
    final List<Map<String, dynamic>> revenueBreakdowns = [];
    final List<Map<String, dynamic>> taxBreakdowns = [];

    void extractBreakdowns(List<SectionRowDto> rows) {
      for (final row in rows) {
        final rb = row.values['revenueBreakdown'];
        if (rb is List) {
          for (final item in rb) {
            if (item is Map) {
              revenueBreakdowns.add(Map<String, dynamic>.from(item));
            }
          }
        }
        final tb = row.values['taxBreakdown'];
        if (tb is List) {
          for (final item in tb) {
            if (item is Map) {
              taxBreakdowns.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    }

    for (final section in sections.sections) {
      extractBreakdowns(section.rows);
    }
    extractBreakdowns(sections.footerRows);

    if (revenueBreakdowns.isEmpty && taxBreakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMultiTaxBreakdown = taxBreakdowns.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (revenueBreakdowns.isNotEmpty) ...[
            Text(
              'Chi tiết doanh thu theo ngành nghề',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildBreakdownTable(
              items: revenueBreakdowns,
              nameKey: 'businessTypeName',
              nameLabel: 'Ngành nghề',
            ),
            const SizedBox(height: 24),
          ],
          if (taxBreakdowns.isNotEmpty) ...[
            Text(
              'Chi tiết thuế',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (hasMultiTaxBreakdown)
              _buildTaxExplanationTable(taxBreakdowns)
            else
              _buildBreakdownTable(
                items: taxBreakdowns,
                nameKey: 'taxType',
                nameLabel: 'Loại thuế',
                hasRate: true,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownTable({
    required List<Map<String, dynamic>> items,
    required String nameKey,
    required String nameLabel,
    bool hasRate = false,
  }) {
    final aggregated = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final name =
          item[nameKey]?.toString() ??
          item['businessType']?.toString() ??
          item['taxName']?.toString() ??
          'Khác';
      final amount = _toNum(item['amount'] ?? item['taxAmount']) ?? 0;
      final rate = item['rate'] ?? item['taxRate'];

      final key = hasRate ? '${name}_$rate' : name;

      if (aggregated.containsKey(key)) {
        aggregated[key]!['amount'] =
            (aggregated[key]!['amount'] as num) + amount;
      } else {
        aggregated[key] = {
          'name': name,
          'amount': amount,
          if (hasRate) 'rate': rate,
        };
      }
    }

    final rows = aggregated.values.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: [
            DataColumn(label: Text(nameLabel, style: _headerStyle())),
            if (hasRate)
              DataColumn(label: Text('Thuế suất', style: _headerStyle())),
            DataColumn(
              label: Text('Số tiền', style: _headerStyle()),
              numeric: true,
            ),
          ],
          rows: rows.map((row) {
            final rateText = row['rate'] != null ? '${row['rate']}%' : '';
            final cellStyle = AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            );
            return DataRow(
              cells: [
                DataCell(Text(row['name'].toString(), style: cellStyle)),
                if (hasRate) DataCell(Text(rateText, style: cellStyle)),
                DataCell(Text(_fmtAmount(row['amount']), style: cellStyle)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaxExplanationTable(List<Map<String, dynamic>> items) {
    final rows = items.map((item) {
      final businessTypeName =
          item['businessTypeName']?.toString().trim().isNotEmpty == true
          ? item['businessTypeName'].toString().trim()
          : 'Khác';
      final taxRate = _toPercentageText(item['taxRate']);
      final taxAmount = _toNum(item['taxAmount']) ?? 0;
      final explanation = item['explanation']?.toString().trim() ?? '';

      return DataRow(
        cells: [
          DataCell(Text(businessTypeName, style: _cellStyle())),
          DataCell(Text(taxRate, style: _cellStyle())),
          DataCell(Text(_fmtAmount(taxAmount), style: _cellStyle())),
          DataCell(
            SizedBox(
              width: 320,
              child: Text(explanation, style: _cellStyle(), softWrap: true),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: [
            DataColumn(label: Text('Ngành nghề', style: _headerStyle())),
            DataColumn(label: Text('Thuế suất', style: _headerStyle())),
            DataColumn(
              label: Text('Số tiền thuế', style: _headerStyle()),
              numeric: true,
            ),
            DataColumn(label: Text('Giải thích', style: _headerStyle())),
          ],
          rows: rows,
        ),
      ),
    );
  }

  TextStyle _cellStyle() =>
      AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary);

  DataRow _buildSummaryRow(
    String label,
    String amount, {
    required String code,
    DateTime? date,
    bool emphasized = false,
    bool taxLike = false,
    String? explanation,
  }) {
    final values = <String, dynamic>{
      'so_hieu': code,
      'ngay_thang': date,
      'dien_giai': label,
      'so_tien': amount,
      'amount': amount,
      'explanation': explanation,
    };
    final style = taxLike
        ? _boldItalicStyle()
        : (emphasized ? _boldStyle() : _normalStyle());
    return DataRow(
      color: WidgetStateProperty.all(
        taxLike ? Colors.orange[50] : (emphasized ? Colors.grey[50] : null),
      ),
      cells: _buildRowCells(values, style),
    );
  }

  List<DataCell> _buildRowCells(Map<String, dynamic> values, TextStyle style) {
    return _effectiveColumns().map((column) {
      final value = _resolveCellValue(values, column.fieldCode);
      return DataCell(
        _buildCellContent(
          text: _formatCellValue(value, column.fieldCode),
          style: style,
          fieldCode: column.fieldCode,
          explanation: values['explanation']?.toString(),
        ),
      );
    }).toList();
  }

  Widget _buildCellContent({
    required String text,
    required TextStyle style,
    required String fieldCode,
    String? explanation,
  }) {
    final normalizedExplanation = explanation?.trim() ?? '';
    if (normalizedExplanation.isEmpty || !_isDescriptionField(fieldCode)) {
      return Text(text, style: style);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: style),
        const SizedBox(height: 4),
        Text(
          normalizedExplanation,
          style: style.copyWith(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimary.withValues(alpha: 0.75),
          ),
          softWrap: true,
        ),
      ],
    );
  }

  bool _isNumericColumn(BookColumnDto column) {
    final code = column.fieldCode.trim().toLowerCase();
    final type = column.fieldType.trim().toLowerCase();
    final label = column.label.trim().toLowerCase();
    return type == 'number' ||
        type == 'money' ||
        code.contains('amount') ||
        code.contains('tien') ||
        label.contains('số tiền');
  }

  dynamic _resolveCellValue(Map<String, dynamic> values, String fieldCode) {
    if (values.containsKey(fieldCode)) return values[fieldCode];
    final code = fieldCode.trim().toLowerCase();
    if (code.contains('so_hieu') ||
        code.contains('voucher') ||
        code.contains('document')) {
      return values['so_hieu'] ?? values['code'];
    }
    if (code.contains('ngay') || code.contains('date')) {
      return values['ngay_thang'] ?? values['date'];
    }
    if (code.contains('dien_giai') ||
        code.contains('description') ||
        code.contains('note')) {
      return values['dien_giai'] ?? values['description'] ?? values['note'];
    }
    if (code.contains('tien') ||
        code.contains('amount') ||
        code.contains('revenue') ||
        code.contains('cost')) {
      return values['so_tien'] ??
          values['amount'] ??
          values['revenue'] ??
          values['cost'];
    }
    return values.entries
        .firstWhere(
          (e) => e.key.trim().toLowerCase() == code,
          orElse: () => const MapEntry('', null),
        )
        .value;
  }

  String _formatCellValue(dynamic value, String fieldCode) {
    final code = fieldCode.trim().toLowerCase();
    if (code.contains('ngay') || code.contains('date')) {
      if (value is DateTime) {
        return _fmtDate(value);
      }
      return _fmtDate(DateTime.tryParse(value?.toString() ?? ''));
    }
    if (code.contains('tien') ||
        code.contains('amount') ||
        code.contains('revenue') ||
        code.contains('cost')) {
      final parsed = _toNum(value);
      return _fmtAmount(parsed ?? value);
    }
    return value?.toString() ?? '';
  }

  // ─── Style helpers ────────────────────────────────────────────────────────

  TextStyle _headerStyle() => AppTextStyles.bodyMedium.copyWith(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  TextStyle _normalStyle() => AppTextStyles.bodyMedium.copyWith(
    color: AppColors.textPrimary,
    fontSize: 15,
  );

  TextStyle _boldStyle() => AppTextStyles.bodyMedium.copyWith(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  TextStyle _boldItalicStyle() => AppTextStyles.bodyMedium.copyWith(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  // ─── Value helpers ────────────────────────────────────────────────────────

  _S2cSummaryData _resolveSummary() {
    final allSummaryRows = <SectionRowDto>[
      ...sections.sections.expand((section) => section.rows),
      ...sections.footerRows,
    ];

    final revenueTotal =
        _findAmountByKeywords(allSummaryRows, const [
          'tổng doanh thu',
          'doanh thu',
        ]) ??
        _sumSectionAmounts('revenue');
    final costTotal =
        _findAmountByKeywords(allSummaryRows, const [
          'tổng chi phí hợp lý',
          'chi phí hợp lý',
        ]) ??
        _sumSectionAmounts('cost');
    final difference =
        _findAmountByKeywords(allSummaryRows, const [
          'chênh lệch',
          'chenh lech',
        ]) ??
        ((revenueTotal != null && costTotal != null)
            ? revenueTotal - costTotal
            : null);
    final pitTax = _findPitAmount(allSummaryRows);

    // Build flat entries lists sorted by date (descending)
    final revenueEntries = _buildFlatEntries(sectionFilter: 'revenue');
    final costEntries = _buildFlatEntries(sectionFilter: 'cost');

    return _S2cSummaryData(
      revenueTotal: revenueTotal,
      costTotal: costTotal,
      revenueEntries: revenueEntries,
      costEntries: costEntries,
      difference: difference,
      pitTax: pitTax,
    );
  }

  List<_S2cEntry> _buildFlatEntries({required String sectionFilter}) {
    final entries = <_S2cEntry>[];
    final matchingRows =
        dataRows.where((row) {
          final rowSection = _inferSection(row)?.trim().toLowerCase();
          final isCostLike = _pickDyn(row, _costHints) != null;
          if (sectionFilter == 'revenue') {
            final isRevenueShape =
                rowSection == 'revenue' ||
                rowSection == null ||
                rowSection.isEmpty;
            return isRevenueShape && !isCostLike;
          }
          return rowSection == sectionFilter || isCostLike;
        }).toList()..sort((a, b) {
          final da = _parseDate(_pickDyn(a, _dateAliases));
          final db = _parseDate(_pickDyn(b, _dateAliases));
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da); // Descending (newest first)
        });

    for (final row in matchingRows) {
      final amount = _toNum(_pickDyn(row, _soTienAliases));
      final rawNote = _pickDyn(row, _descAliases)?.toString() ?? '';
      if (amount == null || rawNote.trim().isEmpty) continue;
      entries.add(
        _S2cEntry(
          code: _pickDyn(row, _soHieuAliases)?.toString() ?? '',
          note: rawNote,
          explanation: _pickDyn(row, const ['explanation'])?.toString().trim(),
          amount: amount,
          date: _parseDate(_pickDyn(row, _dateAliases)),
        ),
      );
    }

    return entries;
  }

  bool _isDescriptionField(String fieldCode) {
    final code = fieldCode.trim().toLowerCase();
    return code.contains('dien_giai') ||
        code.contains('description') ||
        code.contains('note');
  }

  num? _sumSectionAmounts(String section) {
    num sum = 0;
    var hasValue = false;
    for (final row in dataRows) {
      final rowSection = _inferSection(row)?.trim().toLowerCase();
      if (rowSection != section) continue;
      final value = _toNum(_pickDyn(row, _soTienAliases));
      if (value == null) continue;
      sum += value;
      hasValue = true;
    }
    return hasValue ? sum : null;
  }

  num? _findAmountByKeywords(List<SectionRowDto> rows, List<String> keywords) {
    for (final row in rows) {
      final label = (row.values['dien_giai']?.toString() ?? '').toLowerCase();
      if (label.isEmpty) continue;
      final matched = keywords.any((keyword) => label.contains(keyword));
      if (!matched) continue;
      final amount = _toNum(_pickDyn(row.values, _soTienAliases));
      if (amount != null) return amount;
    }
    return null;
  }

  num? _findPitAmount(List<SectionRowDto> rows) {
    for (final row in rows) {
      final label = (row.values['dien_giai']?.toString() ?? '').toLowerCase();
      final taxType = row.taxType?.trim().toUpperCase();
      if (taxType == 'PIT' || taxType == 'TNCN' || label.contains('tncn')) {
        final amount = _toNum(_pickDyn(row.values, _soTienAliases));
        if (amount != null) return amount;
      }
    }
    return null;
  }

  static String? _inferSection(Map<String, dynamic> v) {
    const keys = ['section', 'Section', 'sectionType', 'kind', 'type'];
    for (final key in keys) {
      final value = v[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static dynamic _pickDyn(Map<String, dynamic> v, List<String> aliases) {
    for (final key in aliases) {
      final val = v[key];
      if (val != null && val.toString().trim().isNotEmpty) return val;
    }
    return null;
  }

  static String _fmtAmount(dynamic value) {
    if (value == null) return '';
    if (value is num) return CurrencyFormatter.formatVND(value);
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return CurrencyFormatter.formatVND(parsed);
      return value;
    }
    return value.toString();
  }

  static String _toPercentageText(dynamic value) {
    final numValue = _toNum(value);
    if (numValue == null) return '';
    return '${(numValue * 100).toStringAsFixed(4)} %';
  }

  static String _fmtDate(DateTime? value) {
    if (value == null) return '';
    return DateFormatter.formatDate(value);
  }

  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.replaceAll(',', '').trim());
    }
    return num.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}

class _S2cSummaryData {
  final num? revenueTotal;
  final num? costTotal;
  final List<_S2cEntry> revenueEntries;
  final List<_S2cEntry> costEntries;
  final num? difference;
  final num? pitTax;

  const _S2cSummaryData({
    this.revenueTotal,
    this.costTotal,
    this.revenueEntries = const [],
    this.costEntries = const [],
    this.difference,
    this.pitTax,
  });
}

class _S2cEntry {
  final String code;
  final String note;
  final String? explanation;
  final num amount;
  final DateTime? date;

  const _S2cEntry({
    required this.code,
    required this.note,
    this.explanation,
    required this.amount,
    this.date,
  });
}
