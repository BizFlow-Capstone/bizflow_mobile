import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Widget hiển thị sổ theo dõi xuất nhập tồn kho mẫu S2d-HKD (TT152)
/// 11 cột: Số hiệu CT | Ngày | Diễn giải | ĐVT | Đơn giá | Sl nhập | Tiền nhập | Sl xuất | Tiền xuất | Sl tồn | Tiền tồn
/// Grouped by inventory category (businessTypeName) with subtotals + grand total footer
class S2dBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  static const _businessTypeIdAliases = [
    'businessTypeId',
    'BusinessTypeId',
    'business_type_id',
  ];
  static const _sectionAliases = ['section', 'Section', 'sectionId'];
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
    'ngay',
    'ngay_thang',
    'receivedAt',
    'createdAt',
    'updatedAt',
    'documentDate',
    'date',
  ];
  static const _productNameAliases = [
    '__productName',
    'productName',
    'ProductName',
    'itemName',
    'inventoryName',
    'ten_san_pham',
    'ten_hang_hoa',
    'name',
    'businessTypeName',
  ];
  static const _descAliases = [
    'dien_giai',
    'description',
    'note',
    'planName',
    'businessLocationName',
  ];
  static const _dvtAliases = ['dvt', 'unit', 'unitName'];
  static const _donGiaAliases = ['don_gia', 'unitPrice', 'price'];
  static const _slNhapAliases = [
    'sl_nhap',
    'importQuantity',
    'quantityIn',
    'slNhap',
  ];
  static const _tienNhapAliases = [
    'tien_nhap',
    'importAmount',
    'amountIn',
    'tienNhap',
  ];
  static const _slXuatAliases = [
    'sl_xuat',
    'exportQuantity',
    'quantityOut',
    'slXuat',
  ];
  static const _tienXuatAliases = [
    'tien_xuat',
    'exportAmount',
    'amountOut',
    'tienXuat',
  ];
  static const _slTonAliases = [
    'sl_ton',
    'remainingQuantity',
    'stockQuantity',
    'slTon',
    'tonCuoiKy',
  ];
  static const _tienTonAliases = [
    'tien_ton',
    'remainingAmount',
    'stockAmount',
    'tienTon',
  ];

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
    final consumedIndexes = <int>{};
    final productNameBySection = <String, String>{};
    final productNameByBusinessType = <String, String>{};

    for (final section in sections.sections) {
      final sectionName = section.businessTypeName?.trim();
      if (sectionName == null || sectionName.isEmpty) continue;

      final businessTypeKey = section.businessTypeId?.trim();
      if (businessTypeKey != null && businessTypeKey.isNotEmpty) {
        productNameByBusinessType[businessTypeKey] = sectionName;
        // For S2D: section.businessTypeId = ProductId, and data rows
        // have section = ProductId.  Map it so the fallback lookup works.
        productNameBySection.putIfAbsent(businessTypeKey, () => sectionName);
      }

      for (final row in section.rows) {
        final sectionKey = row.section?.trim();
        if (sectionKey != null && sectionKey.isNotEmpty) {
          productNameBySection[sectionKey] = sectionName;
        }

        final rowBusinessTypeKey = row.businessTypeId?.trim();
        if (rowBusinessTypeKey != null && rowBusinessTypeKey.isNotEmpty) {
          productNameByBusinessType[rowBusinessTypeKey] = sectionName;
        }
      }
    }

    for (final section in sections.sections) {
      for (final row in section.rows) {
        switch (row.lineType) {
          case 'data_placeholder':
            final filter = row.businessTypeId ?? section.businessTypeId;
            final sectionFilter = row.section;
            final matching = dataRows.asMap().entries.where((entry) {
              final index = entry.key;
              final r = entry.value;
              if (consumedIndexes.contains(index)) return false;

              // Accept when businessTypeId matches OR the section field matches
              // the filter (S2D: BE sends dataFilter.productId = ProductId, which
              // falls back to section.businessTypeId = ProductId, but data rows
              // have section = ProductId, not businessTypeId).
              if (filter != null) {
                final btId = _extractBusinessTypeId(r);
                if (btId != filter && _extractSectionValue(r) != filter) {
                  return false;
                }
              }
              if (sectionFilter != null &&
                  _extractSectionValue(r) != sectionFilter) {
                return false;
              }
              if (filter == null && sectionFilter == null) {
                return consumedIndexes.isEmpty;
              }
              return true;
            });
            for (final entry in matching) {
              consumedIndexes.add(entry.key);
              tableRows.add(
                _buildDataRow(
                  SectionRowDto(
                    lineType: 'data',
                    values: {
                      ...entry.value,
                      '__productName': _resolveProductName(
                        entry.value,
                        section: section,
                        productNameBySection: productNameBySection,
                        productNameByBusinessType: productNameByBusinessType,
                      ),
                    },
                  ),
                ),
              );
            }
            break;
          case 'data':
            tableRows.add(
              _buildDataRow(
                SectionRowDto(
                  lineType: row.lineType,
                  values: {
                    ...row.values,
                    '__productName': _resolveProductName(
                      row.values,
                      section: section,
                      productNameBySection: productNameBySection,
                      productNameByBusinessType: productNameByBusinessType,
                    ),
                  },
                ),
              ),
            );
            break;
          case 'subtotal':
            tableRows.add(_buildSubtotalRow(row));
            break;
          case 'opening_inventory':
          case 'inventory_inbound':
          case 'inventory_outbound':
          case 'closing_inventory':
            tableRows.add(
              _buildInventorySummaryRow(
                SectionRowDto(
                  lineType: row.lineType,
                  values: {
                    ...row.values,
                    '__productName': _resolveProductName(
                      row.values,
                      section: section,
                      productNameBySection: productNameBySection,
                      productNameByBusinessType: productNameByBusinessType,
                    ),
                  },
                ),
              ),
            );
            break;
          case 'industry_header':
          case 'section_header':
            break;
          default:
            break;
        }
      }
    }

    if (consumedIndexes.isEmpty && dataRows.isNotEmpty) {
      for (final dataRow in dataRows) {
        tableRows.add(
          _buildDataRow(
            SectionRowDto(
              lineType: 'data',
              values: {
                ...dataRow,
                '__productName': _resolveProductName(
                  dataRow,
                  productNameBySection: productNameBySection,
                  productNameByBusinessType: productNameByBusinessType,
                ),
              },
            ),
          ),
        );
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
          DataColumn(label: Text('Tên sản phẩm', style: headerStyle)),
          DataColumn(label: Text('Diễn giải', style: headerStyle)),
          DataColumn(label: Text('ĐVT', style: headerStyle)),
          DataColumn(label: Text('Đơn giá', style: headerStyle), numeric: true),
          DataColumn(label: Text('SL nhập', style: headerStyle), numeric: true),
          DataColumn(
            label: Text('Tiền nhập', style: headerStyle),
            numeric: true,
          ),
          DataColumn(label: Text('SL xuất', style: headerStyle), numeric: true),
          DataColumn(
            label: Text('Tiền xuất', style: headerStyle),
            numeric: true,
          ),
          DataColumn(label: Text('SL tồn', style: headerStyle), numeric: true),
          DataColumn(
            label: Text('Tiền tồn', style: headerStyle),
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
      final name = item[nameKey]?.toString() ??
          item['businessType']?.toString() ??
          item['taxName']?.toString() ??
          'Khác';
      final amount = _parseAmountNum(item['amount'] ?? item['taxAmount']) ?? 0;
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
            DataColumn(
              label: Text(
                nameLabel,
                style: cellStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (hasRate)
              DataColumn(
                label: Text(
                  'Thuế suất',
                  style: cellStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            DataColumn(
              label: Text(
                'Số tiền',
                style: cellStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
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

  DataRow _buildDataRow(SectionRowDto row) {
    final cellStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 13,
    );
    final values = row.values;
    return DataRow(
      cells: [
        DataCell(
          Text(
            _pick(values, _soHieuAliases)?.toString() ?? '',
            style: cellStyle,
          ),
        ),
        DataCell(
          Text(_formatDate(_pick(values, _dateAliases)), style: cellStyle),
        ),
        DataCell(
          Text(
            _pick(values, _productNameAliases)?.toString() ?? '',
            style: cellStyle,
          ),
        ),
        DataCell(
          Text(_pick(values, _descAliases)?.toString() ?? '', style: cellStyle),
        ),
        DataCell(
          Text(_pick(values, _dvtAliases)?.toString() ?? '', style: cellStyle),
        ),
        DataCell(
          Text(_formatAmount(_pick(values, _donGiaAliases)), style: cellStyle),
        ),
        DataCell(
          Text(_formatQty(_pick(values, _slNhapAliases)), style: cellStyle),
        ),
        DataCell(
          Text(
            _formatAmount(_pick(values, _tienNhapAliases)),
            style: cellStyle,
          ),
        ),
        DataCell(
          Text(_formatQty(_pick(values, _slXuatAliases)), style: cellStyle),
        ),
        DataCell(
          Text(
            _formatAmount(_pick(values, _tienXuatAliases)),
            style: cellStyle,
          ),
        ),
        DataCell(
          Text(_formatQty(_pick(values, _slTonAliases)), style: cellStyle),
        ),
        DataCell(
          Text(_formatAmount(_pick(values, _tienTonAliases)), style: cellStyle),
        ),
      ],
    );
  }

  String? _extractBusinessTypeId(Map<String, dynamic> row) {
    final value = _pick(row, _businessTypeIdAliases);
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _extractSectionValue(Map<String, dynamic> row) {
    final value = _pick(row, _sectionAliases);
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _extractProductName(Map<String, dynamic> row) {
    final value = _pick(row, _productNameAliases);
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _resolveProductName(
    Map<String, dynamic> row, {
    BookSectionResponseDto? section,
    required Map<String, String> productNameBySection,
    required Map<String, String> productNameByBusinessType,
  }) {
    final explicit = _extractProductName(row);
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final sectionName = section?.businessTypeName?.trim();
    if (sectionName != null && sectionName.isNotEmpty) return sectionName;

    final sectionKey = _extractSectionValue(row);
    if (sectionKey != null) {
      final mapped = productNameBySection[sectionKey];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }

    final businessTypeKey = _extractBusinessTypeId(row);
    if (businessTypeKey != null) {
      final mapped = productNameByBusinessType[businessTypeKey];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }

    return null;
  }

  dynamic _pick(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) return value;
    }
    return null;
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
            _pick(row.values, _productNameAliases)?.toString() ?? '',
            style: style,
          ),
        ),
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

  DataRow _buildInventorySummaryRow(SectionRowDto row) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final label = switch (row.lineType) {
      'opening_inventory' => 'Tồn đầu kỳ',
      'inventory_inbound' => 'Nhập trong kỳ',
      'inventory_outbound' => 'Xuất trong kỳ',
      'closing_inventory' => 'Tồn cuối kỳ',
      _ => row.values['dien_giai']?.toString() ?? 'Tổng hợp kho',
    };

    return DataRow(
      color: WidgetStateProperty.all(Colors.indigo[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            _pick(row.values, _productNameAliases)?.toString() ?? '',
            style: style,
          ),
        ),
        DataCell(Text(label, style: style)),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(_formatQty(_pick(row.values, _slNhapAliases)), style: style),
        ),
        DataCell(
          Text(
            _formatAmount(_pick(row.values, _tienNhapAliases)),
            style: style,
          ),
        ),
        DataCell(
          Text(_formatQty(_pick(row.values, _slXuatAliases)), style: style),
        ),
        DataCell(
          Text(
            _formatAmount(_pick(row.values, _tienXuatAliases)),
            style: style,
          ),
        ),
        DataCell(
          Text(_formatQty(_pick(row.values, _slTonAliases)), style: style),
        ),
        DataCell(
          Text(
            _formatAmount(
              _pick(row.values, _tienTonAliases) ?? row.values['so_tien'],
            ),
            style: style,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String && value.isNotEmpty) {
      date = DateTime.tryParse(value);
    }
    if (date != null) {
      return DateFormatter.formatDate(date);
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
