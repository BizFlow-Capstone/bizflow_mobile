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
    'so_tien', 'revenue', 'cost', 'finalAmount', 'totalAmount', 'amount',
    'planPrice',
  ];
  static const _businessTypeIdAliases = [
    'businessTypeId',
    'BusinessTypeId',
    'business_type_id',
  ];
  static const _businessTypeNameAliases = [
    'businessTypeName',
    'BusinessTypeName',
    'businessType',
    'industryName',
    'industry',
    'nganh_nghe',
  ];
  static const _soHieuAliases = [
    'so_hieu', 'importCode', 'orderCode', 'bookCode', 'code', 'importId',
    'CostId', 'costId',
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
        children: [_buildHeader(context), _buildTable(context, summary)],
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
    tableRows.addAll(_buildIndustryRows(summary.revenueGroups));

    tableRows.add(
      _buildSummaryRow(
        code: '',
        '2. Chi phí hợp lý',
        _fmtAmount(summary.costTotal),
        emphasized: true,
      ),
    );
    tableRows.addAll(_buildIndustryRows(summary.costGroups));

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
        columns: [
          DataColumn(label: Text('Số hiệu', style: _headerStyle())),
          DataColumn(label: Text('Ngày, tháng', style: _headerStyle())),
          DataColumn(label: Text('Diễn giải', style: _headerStyle())),
          DataColumn(label: Text('Số tiền', style: _headerStyle()), numeric: true),
        ],
        rows: tableRows,
      ),
    );
  }

  List<DataRow> _buildIndustryRows(List<_S2cIndustryGroup> groups) {
    final rows = <DataRow>[];
    for (final group in groups) {
      if (!_isStructuralSummaryLabel(group.label)) {
        rows.add(_buildIndustryHeaderRow(group.label));
      }
      rows.addAll(
        group.entries.map(
          (entry) => _buildSummaryRow(
            code: entry.code,
            date: entry.date,
            entry.note,
            _fmtAmount(entry.amount),
          ),
        ),
      );
    }
    return rows;
  }

  DataRow _buildIndustryHeaderRow(String label) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.amber[50]),
      cells: [
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            label,
            style: _boldItalicStyle(),
          ),
        ),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  DataRow _buildSummaryRow(
    String label,
    String amount, {
    required String code,
    DateTime? date,
    bool emphasized = false,
    bool taxLike = false,
  }) {
    return DataRow(
      color: WidgetStateProperty.all(
        taxLike ? Colors.orange[50] : (emphasized ? Colors.grey[50] : null),
      ),
      cells: [
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              code,
              style: taxLike
                  ? _boldItalicStyle()
                  : (emphasized ? _boldStyle() : _normalStyle()),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 110,
            child: Text(
              _fmtDate(date),
              textAlign: TextAlign.center,
              style: taxLike
                  ? _boldItalicStyle()
                  : (emphasized ? _boldStyle() : _normalStyle()),
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 480, maxWidth: 680),
            child: Text(
              label,
              style: taxLike
                  ? _boldItalicStyle()
                  : (emphasized ? _boldStyle() : _normalStyle()),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: taxLike
                  ? _boldItalicStyle()
                  : (emphasized ? _boldStyle() : _normalStyle()),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Style helpers ────────────────────────────────────────────────────────

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

  // ─── Value helpers ────────────────────────────────────────────────────────

  _S2cSummaryData _resolveSummary() {
    final allSummaryRows = <SectionRowDto>[
      ...sections.sections.expand((section) => section.rows),
      ...sections.footerRows,
    ];

    final revenueTotal =
        _findAmountByKeywords(allSummaryRows, const ['tổng doanh thu', 'doanh thu']) ??
        _sumSectionAmounts('revenue');
    final costTotal =
        _findAmountByKeywords(allSummaryRows, const ['tổng chi phí hợp lý', 'chi phí hợp lý']) ??
        _sumSectionAmounts('cost');
    final difference =
        _findAmountByKeywords(allSummaryRows, const ['chênh lệch', 'chenh lech']) ??
        ((revenueTotal != null && costTotal != null) ? revenueTotal - costTotal : null);
    final pitTax = _findPitAmount(allSummaryRows);

    return _S2cSummaryData(
      revenueTotal: revenueTotal,
      costTotal: costTotal,
      revenueGroups: _buildEntryGroups(sectionFilter: 'revenue'),
      costGroups: _buildEntryGroups(sectionFilter: 'cost'),
      difference: difference,
      pitTax: pitTax,
    );
  }

  List<_S2cIndustryGroup> _buildEntryGroups({required String sectionFilter}) {
    // Only use sections-based grouping when sections have per-industry structure
    // (businessTypeName populated per section — S2a/S2b pattern).
    // S2c uses per_section path: sections are structural (revenue/cost blocks),
    // not per-industry, so businessTypeName is absent → use dataRows grouping.
    final matchingSections = sections.sections.where((s) {
      final st = s.sectionType.trim().toLowerCase();
      if (st == sectionFilter) return true;
      if (st == 'revenue_cost') {
        final groupKey = s.businessTypeId?.trim().toLowerCase();
        return groupKey == sectionFilter;
      }
      return false;
    }).toList();

    final hasIndustryStructure = matchingSections.any(
      (s) => s.businessTypeName?.trim().isNotEmpty == true,
    );

    final isRevenueCostStructure = matchingSections.any(
      (s) => s.sectionType.trim().toLowerCase() == 'revenue_cost',
    );

    // For S2c revenue_cost sections, labels like "I. DOANH THU" / "II. CHI PHI"
    // are structural, not industry groups. Use data-driven grouping instead.
    if (isRevenueCostStructure) {
      return _buildGroupsFromDataRows(sectionFilter);
    }

    if (matchingSections.isNotEmpty && hasIndustryStructure) {
      return _buildGroupsFromSections(matchingSections);
    }

    // Also check all sections in case sectionType is not explicitly labelled
    // (S2a/S2b style where each section = one industry group).
    if (sectionFilter == 'revenue') {
      final allWithIndustry = sections.sections
          .where((s) => s.businessTypeName?.trim().isNotEmpty == true)
          .toList();
      if (allWithIndustry.isNotEmpty) {
        return _buildGroupsFromSections(allWithIndustry);
      }

      // Requirement: revenue detail is shown only when revenue sections exist.
      // If revenue sections are not available yet, keep summary-only for revenue.
      return const [];
    }

    return _buildGroupsFromDataRows(sectionFilter);
  }

  List<_S2cIndustryGroup> _buildGroupsFromSections(
    List<BookSectionResponseDto> sectionList,
  ) {
    final result = <_S2cIndustryGroup>[];
    final sorted = [...sectionList]
      ..sort((a, b) => a.groupIndex.compareTo(b.groupIndex));

    for (final section in sorted) {
      final groupLabel =
          (section.businessTypeName?.trim().isNotEmpty == true)
          ? section.businessTypeName!
          : 'Ngành nghề';

      final entries = <_S2cEntry>[];
      for (final row in section.rows) {
        if (row.lineType.trim().toLowerCase() != 'data_placeholder') continue;
        final btFilter = row.businessTypeId ?? section.businessTypeId;
        final sectionFilter =
            row.section?.trim().toLowerCase() ?? section.sectionType.trim().toLowerCase();
        final matching = dataRows.where((dataRow) {
          final rowSection = _inferSection(dataRow)?.trim().toLowerCase();
          if (sectionFilter.isNotEmpty &&
              sectionFilter != 'revenue_cost' &&
              rowSection != sectionFilter) {
            return false;
          }
          if (btFilter == null || btFilter.isEmpty) return true;
          final dataBt = dataRow['businessTypeId']?.toString();
          return dataBt == btFilter || rowSection == btFilter.toLowerCase();
        }).toList()
          ..sort((a, b) {
            final da = _parseDate(_pickDyn(a, _dateAliases));
            final db = _parseDate(_pickDyn(b, _dateAliases));
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });

        for (final dataRow in matching) {
          final amount = _toNum(_pickDyn(dataRow, _soTienAliases));
          final rawNote =
              _pickDyn(dataRow, _descAliases)?.toString().trim() ?? '';
          if (amount == null || rawNote.isEmpty) continue;
          entries.add(
            _S2cEntry(
              code: _pickDyn(dataRow, _soHieuAliases)?.toString() ?? '',
              note: rawNote,
              amount: amount,
              date: _parseDate(_pickDyn(dataRow, _dateAliases)),
            ),
          );
        }
      }

      if (entries.isNotEmpty) {
        result.add(_S2cIndustryGroup(label: groupLabel, entries: entries));
      }
    }
    return result;
  }

  List<_S2cIndustryGroup> _buildGroupsFromDataRows(String sectionFilter) {
    final seeds = _buildIndustrySeeds();
    final groups = <String, _PendingIndustryGroup>{};
    final matchingRows = dataRows.where((row) {
      final rowSection = _inferSection(row)?.trim().toLowerCase();
      final isCostLike = _pickDyn(row, _costHints) != null;
      if (sectionFilter == 'revenue') {
        // Revenue rows are either explicitly tagged 'revenue' or have no section
        // tag at all (raw transaction data from the /rows API has no section field).
        final isRevenueShape =
            rowSection == 'revenue' || rowSection == null || rowSection.isEmpty;
        return isRevenueShape && !isCostLike;
      }
      return rowSection == sectionFilter || isCostLike;
    }).toList()
      ..sort((a, b) {
        final da = _parseDate(_pickDyn(a, _dateAliases));
        final db = _parseDate(_pickDyn(b, _dateAliases));
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    for (final row in matchingRows) {
      final amount = _toNum(_pickDyn(row, _soTienAliases));
      final rawNote = _pickDyn(row, _descAliases)?.toString().trim() ?? '';
      if (amount == null || rawNote.isEmpty) continue;

      final industry = _resolveIndustry(row, rawNote, seeds);
      final group = groups.putIfAbsent(
        industry.key,
        () => _PendingIndustryGroup(
          key: industry.key,
          label: industry.label,
          order: industry.order,
        ),
      );
      group.entries.add(
        _S2cEntry(
          code: _pickDyn(row, _soHieuAliases)?.toString() ?? '',
          note: _normalizeNoteForGroup(rawNote, industry.label),
          amount: amount,
          date: _parseDate(_pickDyn(row, _dateAliases)),
        ),
      );
    }

    final built = groups.values.toList()
      ..sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    return built
        .map(
          (group) => _S2cIndustryGroup(
            label: group.label,
            entries: List<_S2cEntry>.unmodifiable(group.entries),
          ),
        )
        .where((group) => group.entries.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, _IndustrySeed> _buildIndustrySeeds() {
    final seeds = <String, _IndustrySeed>{};
    final orderedSections = [...sections.sections]
      ..sort((a, b) => a.groupIndex.compareTo(b.groupIndex));
    for (final section in orderedSections) {
      final label = section.businessTypeName?.trim() ?? '';
      final id = section.businessTypeId?.trim() ?? '';
      final order = section.groupIndex <= 0 ? 9999 : section.groupIndex;
      if (id.isNotEmpty) {
        seeds['id:$id'] = _IndustrySeed(
          label: label.isEmpty ? 'Ngành nghề khác' : label,
          order: order,
        );
      }
      if (label.isNotEmpty) {
        seeds['name:${_normalizeKey(label)}'] = _IndustrySeed(
          label: label,
          order: order,
        );
      }

      for (final row in section.rows) {
        final breakdown = row.values['revenueBreakdown'];
        if (breakdown is! List) continue;
        for (final item in breakdown) {
          if (item is! Map) continue;
          final btId = item['businessTypeId']?.toString().trim() ?? '';
          final btName = item['businessTypeName']?.toString().trim() ?? '';
          if (btId.isEmpty || btName.isEmpty) continue;
          seeds['id:$btId'] = _IndustrySeed(label: btName, order: order);
          seeds['name:${_normalizeKey(btName)}'] = _IndustrySeed(
            label: btName,
            order: order,
          );
        }
      }
    }
    return seeds;
  }

  _ResolvedIndustry _resolveIndustry(
    Map<String, dynamic> row,
    String rawNote,
    Map<String, _IndustrySeed> seeds,
  ) {
    final businessTypeId = _pickDyn(row, _businessTypeIdAliases)?.toString().trim();
    if (businessTypeId != null && businessTypeId.isNotEmpty) {
      final byId = seeds['id:$businessTypeId'];
      if (byId != null) {
        return _ResolvedIndustry(
          key: 'id:$businessTypeId',
          label: byId.label,
          order: byId.order,
        );
      }
    }

    final businessTypeName = _pickDyn(row, _businessTypeNameAliases)?.toString().trim();
    if (businessTypeName != null && businessTypeName.isNotEmpty) {
      final key = 'name:${_normalizeKey(businessTypeName)}';
      final seeded = seeds[key];
      return _ResolvedIndustry(
        key: key,
        label: seeded?.label ?? businessTypeName,
        order: seeded?.order ?? 10000,
      );
    }

    final colonIndex = rawNote.indexOf(':');
    if (colonIndex > 0) {
      final prefix = rawNote.substring(0, colonIndex).trim();
      if (prefix.isNotEmpty && prefix.length <= 80) {
        final key = 'name:${_normalizeKey(prefix)}';
        final seeded = seeds[key];
        return _ResolvedIndustry(
          key: key,
          label: seeded?.label ?? prefix,
          order: seeded?.order ?? 10000,
        );
      }
    }

    return const _ResolvedIndustry(
      key: 'name:khac',
      label: 'Khác',
      order: 10001,
    );
  }

  static String _normalizeNoteForGroup(String note, String groupLabel) {
    final normalizedNote = note.trim();
    final colonIndex = normalizedNote.indexOf(':');
    if (colonIndex <= 0) return normalizedNote;

    final prefix = normalizedNote.substring(0, colonIndex).trim();
    if (_normalizeKey(prefix) != _normalizeKey(groupLabel)) return normalizedNote;

    final trimmed = normalizedNote.substring(colonIndex + 1).trim();
    return trimmed.isEmpty ? normalizedNote : trimmed;
  }

  static String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _isStructuralSummaryLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized.contains('doanh thu') || normalized.contains('chi phí');
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
  final List<_S2cIndustryGroup> revenueGroups;
  final List<_S2cIndustryGroup> costGroups;
  final num? difference;
  final num? pitTax;

  const _S2cSummaryData({
    this.revenueTotal,
    this.costTotal,
    this.revenueGroups = const [],
    this.costGroups = const [],
    this.difference,
    this.pitTax,
  });
}

class _S2cIndustryGroup {
  final String label;
  final List<_S2cEntry> entries;

  const _S2cIndustryGroup({
    required this.label,
    this.entries = const [],
  });
}

class _S2cEntry {
  final String code;
  final String note;
  final num amount;
  final DateTime? date;

  const _S2cEntry({
    required this.code,
    required this.note,
    required this.amount,
    this.date,
  });
}

class _PendingIndustryGroup {
  final String key;
  final String label;
  final int order;
  final List<_S2cEntry> entries = [];

  _PendingIndustryGroup({
    required this.key,
    required this.label,
    required this.order,
  });
}

class _IndustrySeed {
  final String label;
  final int order;

  const _IndustrySeed({
    required this.label,
    required this.order,
  });
}

class _ResolvedIndustry {
  final String key;
  final String label;
  final int order;

  const _ResolvedIndustry({
    required this.key,
    required this.label,
    required this.order,
  });
}
