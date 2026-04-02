import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';

/// Widget hiển thị sổ theo dõi xuất nhập tồn kho mẫu S2d-HKD (TT152)
/// 11 cột: Số hiệu CT | Ngày | Diễn giải | ĐVT | Đơn giá | Sl nhập | Tiền nhập | Sl xuất | Tiền xuất | Sl tồn | Tiền tồn
/// Grouped by inventory category (businessTypeName) with subtotals + grand total footer
class S2dBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S2dBookWidget({
    super.key,
    required this.sections,
    this.dataRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildHeader(context), _buildTable(context)],
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
            'Mẫu số S2d-HKD',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SỔ THEO DÕI XUẤT NHẬP TỒN HÀNG HÓA',
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

    for (final section in sections.sections) {
      tableRows.add(_buildSectionHeaderRow(section));

      for (final row in section.rows) {
        switch (row.lineType) {
          case 'data_placeholder':
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
          case 'industry_header':
            break;
          default:
            tableRows.add(_buildDataRow(row));
        }
      }
    }

    for (final row in sections.footerRows) {
      tableRows.add(_buildGrandTotalRow(row));
    }

    final headerStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
        columnSpacing: 12,
        columns: [
          DataColumn(label: Text('Số hiệu CT', style: headerStyle)),
          DataColumn(label: Text('Ngày', style: headerStyle)),
          DataColumn(label: Text('Diễn giải', style: headerStyle)),
          DataColumn(label: Text('ĐVT', style: headerStyle)),
          DataColumn(
            label: Text('Đơn giá', style: headerStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text('SL nhập', style: headerStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text('Tiền nhập', style: headerStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text('SL xuất', style: headerStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text('Tiền xuất', style: headerStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text('SL tồn', style: headerStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text('Tiền tồn', style: headerStyle),
            numeric: true,
          ),
        ],
        rows: tableRows,
      ),
    );
  }

  DataRow _buildSectionHeaderRow(BookSectionResponseDto section) {
    final label =
        '${section.groupIndex}. ${section.businessTypeName ?? 'Hàng hóa'}';
    return DataRow(
      color: WidgetStateProperty.all(Colors.amber[50]),
      cells: [
        DataCell(
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  DataRow _buildDataRow(SectionRowDto row) {
    final cellStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 13,
    );
    return DataRow(
      cells: [
        DataCell(Text(row.values['so_hieu']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(_formatDate(row.values['ngay']), style: cellStyle)),
        DataCell(Text(row.values['dien_giai']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(row.values['dvt']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(_formatAmount(row.values['don_gia']), style: cellStyle)),
        DataCell(Text(_formatQty(row.values['sl_nhap']), style: cellStyle)),
        DataCell(Text(_formatAmount(row.values['tien_nhap']), style: cellStyle)),
        DataCell(Text(_formatQty(row.values['sl_xuat']), style: cellStyle)),
        DataCell(Text(_formatAmount(row.values['tien_xuat']), style: cellStyle)),
        DataCell(Text(_formatQty(row.values['sl_ton']), style: cellStyle)),
        DataCell(Text(_formatAmount(row.values['tien_ton']), style: cellStyle)),
      ],
    );
  }

  DataRow _buildSubtotalRow(SectionRowDto row) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 13,
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
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(_formatQty(row.values['sl_nhap']), style: style)),
        DataCell(Text(_formatAmount(row.values['tien_nhap']), style: style)),
        DataCell(Text(_formatQty(row.values['sl_xuat']), style: style)),
        DataCell(Text(_formatAmount(row.values['tien_xuat']), style: style)),
        DataCell(Text(_formatQty(row.values['sl_ton']), style: style)),
        DataCell(Text(_formatAmount(row.values['tien_ton']), style: style)),
      ],
    );
  }

  DataRow _buildGrandTotalRow(SectionRowDto row) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            row.values['dien_giai']?.toString() ?? 'Tổng cộng XNT',
            style: style,
          ),
        ),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(_formatQty(row.values['sl_nhap']), style: style)),
        DataCell(Text(_formatAmount(row.values['tien_nhap']), style: style)),
        DataCell(Text(_formatQty(row.values['sl_xuat']), style: style)),
        DataCell(Text(_formatAmount(row.values['tien_xuat']), style: style)),
        DataCell(Text(_formatQty(row.values['sl_ton']), style: style)),
        DataCell(Text(_formatAmount(row.values['tien_ton']), style: style)),
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

  String _formatQty(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      if (value == 0) return '';
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        if (parsed == 0) return '';
        return parsed % 1 == 0
            ? parsed.toInt().toString()
            : parsed.toStringAsFixed(2);
      }
      return value;
    }
    return value.toString();
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      if (value == 0) return '';
      return CurrencyFormatter.formatVND(value);
    }
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        if (parsed == 0) return '';
        return CurrencyFormatter.formatVND(parsed);
      }
      return value;
    }
    return value.toString();
  }
}
