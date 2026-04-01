import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';

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
            style: AppTextStyles.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SỔ DOANH THU BÁN HÀNG HÓA, DỊCH VỤ',
            style: AppTextStyles.bodyLarge.copyWith(
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
              tableRows.add(_buildDataRow(
                SectionRowDto(lineType: 'data', values: dataRow),
              ));
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
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Số hiệu CT', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Ngày, tháng', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Diễn giải', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
            label: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
        ],
        rows: tableRows,
      ),
    );
  }

  DataRow _buildSectionHeaderRow(BookSectionResponseDto section) {
    final label = '${section.groupIndex}. ${section.businessTypeName ?? 'Ngành nghề'}';
    return DataRow(
      color: WidgetStateProperty.all(Colors.amber[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        )),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  DataRow _buildDataRow(SectionRowDto row) {
    return DataRow(
      cells: [
        DataCell(Text(
          row.values['so_hieu']?.toString() ?? '',
          style: AppTextStyles.bodySmall,
        )),
        DataCell(Text(
          _formatDate(row.values['ngay_thang']),
          style: AppTextStyles.bodySmall,
        )),
        DataCell(Text(
          row.values['dien_giai']?.toString() ?? '',
          style: AppTextStyles.bodySmall,
        )),
        DataCell(Text(
          _formatAmount(row.values['so_tien']),
          style: AppTextStyles.bodySmall,
        )),
      ],
    );
  }

  DataRow _buildSubtotalRow(SectionRowDto row) {
    final style = AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold);
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(
          row.values['dien_giai']?.toString() ?? 'Tổng cộng',
          style: style,
        )),
        DataCell(Text(
          _formatAmount(row.values['so_tien']),
          style: style,
        )),
      ],
    );
  }

  DataRow _buildTaxRow(SectionRowDto row) {
    final taxLabel = row.values['dien_giai']?.toString() ?? row.taxType ?? 'Thuế';
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(
          taxLabel,
          style: AppTextStyles.bodySmall.copyWith(
            fontStyle: FontStyle.italic,
          ),
        )),
        DataCell(Text(
          _formatAmount(row.values['so_tien']),
          style: AppTextStyles.bodySmall.copyWith(
            fontStyle: FontStyle.italic,
          ),
        )),
      ],
    );
  }

  DataRow _buildGrandTotalRow(SectionRowDto row) {
    final style = AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold);
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(
          row.values['dien_giai']?.toString() ?? '',
          style: style,
        )),
        DataCell(Text(
          _formatAmount(row.values['so_tien']),
          style: style,
        )),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    if (value is String && value.isNotEmpty) {
      try {
        final date = DateTime.parse(value);
        return '${date.day}/${date.month}';
      } catch (_) {
        return value;
      }
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
