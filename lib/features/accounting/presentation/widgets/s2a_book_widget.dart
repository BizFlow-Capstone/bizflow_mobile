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
        columns: [
          DataColumn(
            label: Text(
              'Số hiệu CT',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Ngày, tháng',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Diễn giải',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Số tiền',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            numeric: true,
          ),
        ],
        rows: tableRows,
      ),
    );
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
    return DataRow(
      color: WidgetStateProperty.all(Colors.amber[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  DataRow _buildDataRow(SectionRowDto row) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            row.values['so_hieu']?.toString() ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(row.values['ngay_thang']),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(
          Text(
            row.values['dien_giai']?.toString() ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatAmount(_pickAmount(row.values)),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
      ],
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
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            row.values['dien_giai']?.toString() ?? 'Tổng cộng',
            style: style,
          ),
        ),
        DataCell(Text(_formatAmount(_pickAmount(row.values)), style: style)),
      ],
    );
  }

  DataRow _buildTaxRow(SectionRowDto row) {
    final taxLabel =
        row.values['dien_giai']?.toString() ?? row.taxType ?? 'Thuế';
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            taxLabel,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatAmount(_pickAmount(row.values)),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
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
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(row.values['dien_giai']?.toString() ?? '', style: style)),
        DataCell(Text(_formatAmount(_pickAmount(row.values)), style: style)),
      ],
    );
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
}
