import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Widget hiển thị sổ doanh thu theo mẫu S2a-HKD (TT152)
/// 4 cột: Số hiệu chứng từ | Ngày, tháng | Diễn giải | Số tiền
/// Grouped by business type with subtotals + tax rows per group
class S2aBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S2aBookWidget({
    super.key,
    required this.sections,
    this.dataRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildTable(context),
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
            'Mẫu số S2a-HKD',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SỔ DOANH THU BÁN HÀNG HÓA, DỊCH VỤ',
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

  Widget _buildTable(BuildContext context) {
    final tableRows = <DataRow>[];

    // Build rows per section (each section = a business type group)
    for (final section in sections.sections) {
      // Section header row (e.g. "1. Ngành nghề ...")
      tableRows.add(_buildSectionHeaderRow(section));

      for (final row in section.rows) {
        switch (row.lineType) {
          case 'data_placeholder':
            // Insert matching data rows from /rows API
            final filter = row.businessTypeId ?? section.businessTypeId;
            final matching = dataRows.where((r) {
              if (filter == null) return true;
              return r['businessTypeId']?.toString() == filter;
            }).toList()..sort((a, b) {
              final da = _parseDate(a['ngay_thang'] ?? a['date']);
              final db = _parseDate(b['ngay_thang'] ?? b['date']);
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });
            for (final dataRow in matching) {
              tableRows.add(
                _buildDataRow(SectionRowDto(lineType: 'data', values: dataRow)),
              );
            }
            break;
          case 'data':
            tableRows.add(_buildDataRow(row));
            break;
          case 'subtotal':
            tableRows.add(_buildSubtotalRow(row));
            break;
          case 'tax_line':
          case 'tax':
            tableRows.add(_buildTaxRow(row));
            break;
          case 'industry_header':
            // Already handled by _buildSectionHeaderRow above
            break;
          default:
            tableRows.add(_buildDataRow(row));
        }
      }
    }

    // Footer rows (Tổng số thuế GTGT/TNCN phải nộp)
    for (final row in sections.footerRows) {
      tableRows.add(_buildGrandTotalRow(row));
    }

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
      BookColumnDto(fieldCode: 'so_hieu', label: 'Số hiệu CT', fieldType: 'text'),
      BookColumnDto(fieldCode: 'ngay_thang', label: 'Ngày, tháng', fieldType: 'date'),
      BookColumnDto(fieldCode: 'dien_giai', label: 'Diễn giải', fieldType: 'text'),
      BookColumnDto(fieldCode: 'so_tien', label: 'Số tiền', fieldType: 'money'),
    ];
  }

  List<DataColumn> _buildColumns() {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return _effectiveColumns().map((column) {
      return DataColumn(
        label: Text(column.label, style: style),
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

  num? _parseAmountNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.replaceAll(',', '').trim());
    }
    return num.tryParse(value.toString());
  }

  Widget _buildBreakdownTable({
    required List<Map<String, dynamic>> items,
    required String nameKey,
    required String nameLabel,
    bool hasRate = false,
  }) {
    final aggregated = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final name = item[nameKey]?.toString() ?? item['businessType']?.toString() ?? item['taxName']?.toString() ?? 'Khác';
      final amount = _parseAmountNum(item['amount'] ?? item['taxAmount']) ?? 0;
      final rate = item['rate'] ?? item['taxRate'];

      final key = hasRate ? '${name}_$rate' : name;
      if (aggregated.containsKey(key)) {
        aggregated[key]!['amount'] = (aggregated[key]!['amount'] as num) + amount;
      } else {
        aggregated[key] = {
          'name': name,
          'amount': amount,
          if (hasRate) 'rate': rate,
        };
      }
    }

    final rows = aggregated.values.toList();
    final headerStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    );
    final cellStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
    );
    
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
            DataColumn(label: Text(nameLabel, style: headerStyle)),
            if (hasRate) DataColumn(label: Text('Thuế suất', style: headerStyle)),
            DataColumn(label: Text('Số tiền', style: headerStyle), numeric: true),
          ],
          rows: rows.map((row) {
            final rateText = _toPercentageText(row['rate']);
            return DataRow(
              cells: [
                DataCell(Text(row['name'].toString(), style: cellStyle)),
                if (hasRate) DataCell(Text(rateText, style: cellStyle)),
                DataCell(Text(_formatAmount(row['amount']), style: cellStyle)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _toPercentageText(dynamic value) {
    final parsed = _parseAmountNum(value);
    if (parsed == null) return '';
    return '${(parsed * 1000).toStringAsFixed(4)} %';
  }

  DataRow _buildSectionHeaderRow(BookSectionResponseDto section) {
    final label =
        '${section.groupIndex}. ${section.businessTypeName ?? 'Ngành nghề'}';
    final values = <String, dynamic>{'dien_giai': label};
    return DataRow(
      color: WidgetStateProperty.all(Colors.amber[50]),
      cells: _buildRowCells(values, AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      )),
    );
  }

  DataRow _buildDataRow(SectionRowDto row) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
    );
    return DataRow(
      cells: _buildRowCells(row.values, style),
    );
  }

  DataRow _buildSubtotalRow(SectionRowDto row) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey[50]),
      cells: _buildRowCells(row.values, style),
    );
  }

  DataRow _buildTaxRow(SectionRowDto row) {
    final taxLabel =
        row.values['dien_giai']?.toString() ?? row.taxType ?? 'Thuế';
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange[50]),
      cells: _buildRowCells(
        {...row.values, 'dien_giai': taxLabel},
        AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  DataRow _buildGrandTotalRow(SectionRowDto row) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue[50]),
      cells: _buildRowCells(row.values, style),
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
    if (code.contains('so_hieu') || code.contains('voucher') || code.contains('document')) {
      return values['so_hieu'] ?? values['documentNumber'] ?? values['DocumentNumber'];
    }
    if (code.contains('ngay') || code.contains('date')) {
      return values['ngay_thang'] ?? values['date'] ?? values['documentDate'] ?? values['DocumentDate'];
    }
    if (code.contains('dien_giai') || code.contains('description')) {
      return values['dien_giai'] ?? values['description'];
    }
    if (code.contains('tien') || code.contains('amount') || code.contains('revenue')) {
      return _pickAmount(values);
    }
    return values.entries
        .firstWhere((e) => e.key.trim().toLowerCase() == code, orElse: () => const MapEntry('', null))
        .value;
  }

  String _formatCellValue(dynamic value, String fieldCode) {
    final code = fieldCode.trim().toLowerCase();
    if (code.contains('ngay') || code.contains('date')) {
      return _formatDate(value);
    }
    if (code.contains('tien') || code.contains('amount') || code.contains('revenue')) {
      return _formatAmount(value);
    }
    return value?.toString() ?? '';
  }

  static const _amountAliases = [
    'so_tien', 'revenue', 'finalAmount', 'totalAmount', 'amount', 'planPrice',
  ];

  static dynamic _pickAmount(Map<String, dynamic> values) {
    for (final key in _amountAliases) {
      final v = values[key];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return DateFormatter.formatDate(value);
    }
    if (value is String && value.isNotEmpty) {
      final date = DateTime.tryParse(value);
      if (date != null) {
        return DateFormatter.formatDate(date);
      }
      return value;
    }
    return value.toString();
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '';
    if (value is num) return CurrencyFormatter.formatVND(value);
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return CurrencyFormatter.formatVND(parsed);
      return value;
    }
    return value.toString();
  }

  bool _isDescriptionField(String fieldCode) {
    final code = fieldCode.trim().toLowerCase();
    return code.contains('dien_giai') || code.contains('description') || code.contains('note');
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
