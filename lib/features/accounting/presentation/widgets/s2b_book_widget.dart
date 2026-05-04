import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Widget hiển thị Sổ doanh thu bán hàng hóa, dịch vụ mẫu S2b-HKD (TT152)
/// 5 cột: STT | Số hiệu CT | Ngày tháng | Diễn giải | Số tiền
/// Grouped by business type, subtotals per group + grand total footer
class S2bBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S2bBookWidget({
    super.key,
    required this.sections,
    this.dataRows = const [],
  });

  static const _soTienAliases = [
    'so_tien', 'revenue', 'finalAmount', 'totalAmount', 'amount', 'planPrice',
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
  static const _dateAliases = [
    'ngay_thang', 'receivedAt', 'createdAt', 'updatedAt', 'documentDate', 'date',
  ];
  static const _descAliases = [
    'dien_giai', 'description', 'note', 'planName', 'businessLocationName',
  ];

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
            'Mẫu số S2b-HKD',
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
              tableRows.add(_buildDataRow(
                SectionRowDto(lineType: 'data', values: dataRow),
              ));
            }
          case 'data':
            tableRows.add(_buildDataRow(row));
          case 'industry_header':
            break; // already handled by _buildSectionHeaderRow
          case 'subtotal':
          case 'total':
            tableRows.add(_buildSubtotalRow(row));
          case 'tax_line':
          case 'tax':
            tableRows.add(_buildTaxRow(row));
          default:
            break;
        }
      }
    }

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
          DataColumn(label: Text('Số hiệu CT', style: _headerStyle())),
          DataColumn(label: Text('Ngày, tháng', style: _headerStyle())),
          DataColumn(label: Text('Diễn giải', style: _headerStyle())),
          DataColumn(label: Text('Số tiền', style: _headerStyle()), numeric: true),
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
            if (hasRate) DataColumn(label: Text('Thuế suất', style: _headerStyle())),
            DataColumn(label: Text('Số tiền', style: _headerStyle()), numeric: true),
          ],
          rows: rows.map((row) {
            final rateText = row['rate'] != null ? '${row['rate']}%' : '';
            return DataRow(
              cells: [
                DataCell(Text(row['name'].toString(), style: _normalStyle())),
                if (hasRate) DataCell(Text(rateText, style: _normalStyle())),
                DataCell(Text(_fmtAmount(row['amount']), style: _normalStyle())),
              ],
            );
          }).toList(),
        ),
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

        DataCell(Text(label, style: _boldItalicStyle())),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  DataRow _buildDataRow(SectionRowDto row) {
    final v = row.values;
    return DataRow(
      cells: [
        DataCell(Text(_pick(v, _soHieuAliases), style: _normalStyle())),
        DataCell(Text(_fmtDate(_pickDyn(v, _dateAliases)), style: _normalStyle())),
        DataCell(Text(_pick(v, _descAliases), style: _normalStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _soTienAliases)), style: _normalStyle())),
      ],
    );
  }

  DataRow _buildSubtotalRow(SectionRowDto row) {
    final v = row.values;
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(_pick(v, _descAliases), style: _boldStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _soTienAliases)), style: _boldStyle())),
      ],
    );
  }

  DataRow _buildTaxRow(SectionRowDto row) {
    final v = row.values;
    final label = v['dien_giai']?.toString() ?? row.taxType ?? 'Thuế';
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(label, style: _boldItalicStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _soTienAliases)), style: _boldItalicStyle())),
      ],
    );
  }

  DataRow _buildGrandTotalRow(SectionRowDto row) {
    final v = row.values;
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(_pick(v, _descAliases), style: _boldStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _soTienAliases)), style: _boldStyle())),
      ],
    );
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

  static dynamic _pickDyn(Map<String, dynamic> v, List<String> aliases) {
    for (final key in aliases) {
      final val = v[key];
      if (val != null && val.toString().trim().isNotEmpty) return val;
    }
    return null;
  }

  static String _pick(Map<String, dynamic> v, List<String> aliases) =>
      _pickDyn(v, aliases)?.toString() ?? '';

  static String _fmtDate(dynamic value) {
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
}
