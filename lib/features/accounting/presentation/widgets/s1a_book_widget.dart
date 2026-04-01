import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';

/// Widget hiển thị sổ doanh thu theo mẫu S1a-HKD (TT152)
/// 3 cột: Ngày tháng | Diễn giải | Số tiền
class S1aBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S1aBookWidget({
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
            'Mẫu số S1a-HKD',
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
    // Assemble rows: replace data_placeholder with actual data rows from /rows
    final allRows = <SectionRowDto>[];
    for (final section in sections.sections) {
      for (final sectionRow in section.rows) {
        if (sectionRow.lineType == 'data_placeholder') {
          // Insert matching data rows here
          final filter = sectionRow.businessTypeId ?? sectionRow.section;
          final matching = dataRows.where((r) {
            if (filter == null) return true;
            return r['businessTypeId']?.toString() == filter ||
                r['section']?.toString() == filter;
          });
          for (final row in matching) {
            allRows.add(SectionRowDto(lineType: 'data', values: row));
          }
        } else {
          allRows.add(sectionRow);
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Ngày tháng', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Diễn giải', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
            label: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
        ],
        rows: [
          ...allRows.map((row) => _buildDataRow(row)),
          ...sections.footerRows.map((row) => _buildFooterRow(row)),
        ],
      ),
    );
  }

  DataRow _buildDataRow(SectionRowDto row) {
    final isSubtotal = row.lineType == 'subtotal' || row.lineType == 'total';
    final style = isSubtotal
        ? AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodySmall;

    return DataRow(
      color: isSubtotal ? WidgetStateProperty.all(Colors.grey[50]) : null,
      cells: [
        DataCell(Text(
          _formatDate(row.values['date']),
          style: style,
        )),
        DataCell(Text(
          row.values['description']?.toString() ?? '',
          style: style,
        )),
        DataCell(Text(
          _formatAmount(row.values['revenue']),
          style: style,
        )),
      ],
    );
  }

  DataRow _buildFooterRow(SectionRowDto row) {
    final style = AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold);
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        DataCell(Text(
          row.values['dien_giai']?.toString() ?? row.values['description']?.toString() ?? 'Tổng cộng',
          style: style,
        )),
        DataCell(Text(
          _formatAmount(row.values['revenue'] ?? row.values['so_tien']),
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
