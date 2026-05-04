import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../domain/models/accounting_book.dart';

/// Widget hiển thị Sổ chi tiết tiền mẫu S2e-HKD (TT152)
/// Cấu trúc:
///   I. Tiền mặt
///      - Tiền mặt đầu kỳ
///      - Data rows (thu/chi)
///      - Tổng tiền thu vào, chi ra, tồn cuối kỳ
///   II. Tiền gửi không kỳ hạn
///      - Ngân hàng X
///        - Tiền gửi đầu kỳ
///        - Data rows (gửi/rút)
///        - Tổng gửi vào, rút ra, cuối kỳ
///      - Ngân hàng Y...
class S2eBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S2eBookWidget({
    super.key,
    required this.sections,
    this.dataRows = const [],
  });

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
  static const _thuVaoAliases = [
    'thu_vao', 'thuVao', 'income', 'amountIn', 'deposit', 'revenue', 'finalAmount',
  ];
  static const _chiRaAliases = [
    'chi_ra', 'chiRa', 'expense', 'amountOut', 'withdrawal', 'cost', 'amount',
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
            'Mẫu số S2e-HKD',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SỔ CHI TIẾT TIỀN',
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

    if (sections.sections.isNotEmpty) {
      // Process structured sections from backend
      for (final section in sections.sections) {
        // Section header (e.g., "Tiền mặt", "Tiền gửi không kỳ hạn")
        if (section.businessTypeName?.trim().isNotEmpty == true) {
          final hasExplicitHeader = section.rows.any(
            (r) => r.lineType.toLowerCase() == 'industry_header' ||
                r.lineType.toLowerCase() == 'section_header',
          );
          if (!hasExplicitHeader) {
            tableRows.add(_buildSectionHeaderRow(
              section.businessTypeName!,
            ));
          }
        }

        for (final row in section.rows) {
          final lineType = row.lineType.trim().toLowerCase();
          switch (lineType) {
            case 'industry_header':
            case 'section_header':
              tableRows.add(_buildSectionHeaderRow(
                row.values['dien_giai']?.toString() ?? section.businessTypeName ?? '',
              ));
            case 'bank_header':
              tableRows.add(_buildBankHeaderRow(
                row.values['dien_giai']?.toString() ?? '',
              ));
            case 'data_placeholder':
              final btFilter = row.businessTypeId ?? section.businessTypeId;
              final sFilter = row.section;
              final matching = dataRows.where((r) {
                if (btFilter != null && btFilter.isNotEmpty) {
                    // Accept if businessTypeId matches OR section matches
                    // (BE sends section=cash/bank on rows but businessTypeId=null)
                    final btMatch = r['businessTypeId']?.toString() == btFilter;
                    final sectionMatch = r['section']?.toString() == btFilter;
                    if (!btMatch && !sectionMatch) return false;
                }
                if (sFilter != null && sFilter.isNotEmpty) {
                  return r['section']?.toString() == sFilter;
                }
                return true;
              });
              for (final dataRow in matching) {
                tableRows.add(_buildDataRow(
                  SectionRowDto(lineType: 'data', values: dataRow),
                ));
              }
            case 'data':
              tableRows.add(_buildDataRow(row));
            case 'subtotal':
            case 'total':
              tableRows.add(_buildSubtotalRow(row));
            case 'tax_line':
            case 'tax':
              tableRows.add(_buildTaxRow(row));
            default:
              // Generic row - still display if it has content
              if (_hasContent(row.values)) {
                tableRows.add(_buildGenericRow(row));
              }
          }
        }
      }

      // Footer rows
      for (final row in sections.footerRows) {
        tableRows.add(_buildSubtotalRow(row));
      }
    } else if (dataRows.isNotEmpty) {
      // Fallback: no sections, render raw data rows
      for (final dataRow in dataRows) {
        tableRows.add(_buildDataRow(
          SectionRowDto(lineType: 'data', values: dataRow),
        ));
      }
    }

    // Empty state
    if (tableRows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu sổ chi tiết tiền',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
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
          DataColumn(label: Text('Thu/Gửi vào', style: _headerStyle()), numeric: true),
          DataColumn(label: Text('Chi/Rút ra', style: _headerStyle()), numeric: true),
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

  // ─── Row Builders ───────────────────────────────────────────────────

  /// Bold section header row (e.g., "Tiền mặt", "Tiền gửi không kỳ hạn")
  DataRow _buildSectionHeaderRow(String label) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.amber[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(label, style: _boldStyle())),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  /// Bold italic bank header row (e.g., "Ngân hàng...")
  DataRow _buildBankHeaderRow(String label) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(label, style: _boldItalicStyle())),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  /// Regular data row with all columns populated
  DataRow _buildDataRow(SectionRowDto row) {
    final v = row.values;
    return DataRow(
      cells: [
        DataCell(Text(_pick(v, _soHieuAliases), style: _normalStyle())),
        DataCell(Text(_fmtDate(_pickDyn(v, _dateAliases)), style: _normalStyle())),
        DataCell(Text(_pick(v, _descAliases), style: _normalStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _thuVaoAliases)), style: _normalStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _chiRaAliases)), style: _normalStyle())),
      ],
    );
  }

  /// Bold subtotal / total row
  DataRow _buildSubtotalRow(SectionRowDto row) {
    final v = row.values;
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(_pick(v, _descAliases), style: _boldStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _thuVaoAliases)), style: _boldStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _chiRaAliases)), style: _boldStyle())),
      ],
    );
  }

  /// Tax row (bold italic)
  DataRow _buildTaxRow(SectionRowDto row) {
    final v = row.values;
    final label = v['dien_giai']?.toString() ?? row.taxType ?? 'Thuế';
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(label, style: _boldItalicStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _thuVaoAliases)), style: _boldItalicStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _chiRaAliases)), style: _boldItalicStyle())),
      ],
    );
  }

  /// Generic row for any unrecognized lineType that has content
  DataRow _buildGenericRow(SectionRowDto row) {
    final v = row.values;
    return DataRow(
      cells: [
        DataCell(Text(_pick(v, _soHieuAliases), style: _normalStyle())),
        DataCell(Text(_fmtDate(_pickDyn(v, _dateAliases)), style: _normalStyle())),
        DataCell(Text(_pick(v, _descAliases), style: _normalStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _thuVaoAliases)), style: _normalStyle())),
        DataCell(Text(_fmtAmount(_pickDyn(v, _chiRaAliases)), style: _normalStyle())),
      ],
    );
  }

  // ─── Style helpers ────────────────────────────────────────────────

  TextStyle _headerStyle() => AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold);

  TextStyle _normalStyle() => AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary, fontSize: 15);

  TextStyle _boldStyle() => AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold);

  TextStyle _boldItalicStyle() => AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      );

  // ─── Value helpers ────────────────────────────────────────────────

  static bool _hasContent(Map<String, dynamic> values) {
    for (final value in values.values) {
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized != '-') return true;
    }
    return false;
  }

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
