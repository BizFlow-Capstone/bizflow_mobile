import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

class S2cExportService {
  const S2cExportService._();

  static const _columns = 4;
  static const _codeAliases = [
    'so_hieu',
    'importCode',
    'orderCode',
    'bookCode',
    'code',
    'importId',
    'CostId',
    'costId',
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
  static const _amountAliases = [
    'Amount',
    'finalAmount',
    'totalAmount',
    'amount',
    'planPrice',
    'revenue',
    'so_tien',
  ];
  static const _costHints = [
    'CostType',
    'costType',
    'CostDate',
    'costDate',
    'CostId',
    'costId',
  ];

  static Future<File?> export({
    required AccountingBook book,
    required List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData,
    String businessName = '',
    String taxCode = '',
    String address = '',
    String locationName = '',
    String periodLabel = '',
  }) async {
    final workbook = xlsio.Workbook();
    try {
      final sheet = _ensureSheet(workbook, 'S2c');
      _buildScaffold(sheet);
      _writeBusinessInfo(
        sheet,
        businessName: businessName,
        taxCode: taxCode,
        address: address,
      );
      _writeLabel(
        sheet,
        row: 5,
        label: 'Địa điểm kinh doanh',
        value: locationName,
      );
      _writeLabel(sheet, row: 6, label: 'Kỳ kê khai', value: periodLabel);

      final summary = _resolveSummary(dataRows, sectionsData);
      final signatureStartRow = _writeSummaryRows(sheet, summary);

      _writeSignatureBlock(sheet, startRow: signatureStartRow);

      return await _save(workbook, book.displayName);
    } catch (e, st) {
      // ignore: avoid_print
      print('S2cExportService export failed: $e\n$st');
      return null;
    } finally {
      workbook.dispose();
    }
  }

  static _S2cSummaryData _resolveSummary(
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData,
  ) {
    final allSummaryRows = <SectionRowDto>[
      ...?sectionsData?.sections.expand((section) => section.rows),
      ...?sectionsData?.footerRows,
    ];

    final revenueTotal =
        _findAmountByKeywords(allSummaryRows, const [
          'tổng doanh thu',
          'doanh thu',
        ]) ??
        _sumSectionAmounts(dataRows, 'revenue');
    final costTotal =
        _findAmountByKeywords(allSummaryRows, const [
          'tổng chi phí hợp lý',
          'chi phí hợp lý',
        ]) ??
        _sumSectionAmounts(dataRows, 'cost');
    final difference =
        _findAmountByKeywords(allSummaryRows, const [
          'chênh lệch',
          'chenh lech',
        ]) ??
        ((revenueTotal != null && costTotal != null)
            ? revenueTotal - costTotal
            : null);
    final pitTax = _findPitAmount(allSummaryRows);

    return _S2cSummaryData(
      revenueTotal: revenueTotal,
      costTotal: costTotal,
      revenueGroups: _buildEntryGroups(
        dataRows,
        sectionsData,
        sectionFilter: 'revenue',
      ),
      costGroups: _buildEntryGroups(
        dataRows,
        sectionsData,
        sectionFilter: 'cost',
      ),
      difference: difference,
      pitTax: pitTax,
    );
  }

  static xlsio.Worksheet _ensureSheet(xlsio.Workbook workbook, String name) {
    if (workbook.worksheets.count > 0) {
      final s = workbook.worksheets[0];
      s.name = name;
      return s;
    }
    return workbook.worksheets.addWithName(name);
  }

  static void _buildScaffold(xlsio.Worksheet sheet) {
    sheet.name = 's2c';

    // A1-A7: copy S1a scaffold exactly, changing only the template code.
    sheet.getRangeByIndex(1, 1, 1, 3).merge();
    sheet.getRangeByIndex(5, 1, 5, 4).merge();
    sheet.getRangeByIndex(6, 1, 6, 4).merge();
    sheet.getRangeByIndex(7, 1, 7, 4).merge();

    // A9-A10: same two-level header style as S2a, without A/B/C/1 marker row.
    sheet.getRangeByIndex(9, 1, 9, 2).merge();
    sheet.getRangeByIndex(9, 3, 10, 3).merge();
    sheet.getRangeByIndex(9, 4, 10, 4).merge();

    sheet.getRangeByIndex(1, 1).columnWidth = 14;
    sheet.getRangeByIndex(1, 2).columnWidth = 30;
    sheet.getRangeByIndex(1, 3).columnWidth = 34.44140625;
    sheet.getRangeByIndex(1, 4).columnWidth = 49.7;
    sheet.getRangeByIndex(1, 1).rowHeight = 72.75;

    _setText(sheet, 0, 0, 'HỘ, CÁ NHÂN KINH DOANH:\nMã số thuế:\nĐịa chỉ:');
    _setText(
      sheet,
      0,
      3,
      'Mẫu số S2c-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)',
    );
    _setText(sheet, 4, 0, 'SỔ CHI TIẾT DOANH THU BÁN HÀNG HÓA, DỊCH VỤ');
    _setText(sheet, 5, 0, 'Địa điểm kinh doanh:');
    _setText(sheet, 6, 0, 'Kỳ kê khai:');

    _setText(sheet, 7, 3, 'Đơn vị tính:');
    final unitStyle = _cell(sheet, 7, 3).cellStyle;
    unitStyle.fontName = 'Times New Roman';
    unitStyle.fontSize = 11;
    unitStyle.italic = true;
    unitStyle.hAlign = xlsio.HAlignType.right;

    _setText(sheet, 8, 0, 'Chứng từ');
    _setText(sheet, 8, 2, 'Diễn giải');
    _setText(sheet, 8, 3, 'Số tiền');
    _setText(sheet, 9, 0, 'Số hiệu');
    _setText(sheet, 9, 1, 'Ngày, tháng');

    _applyHeaderRowStyle(sheet, row: 8, fontSize: 10);
    _applyHeaderRowStyle(sheet, row: 9, fontSize: 10);

    for (var col = 0; col < _columns; col++) {
      final style = _cell(sheet, 9, col).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 10;
      style.hAlign = xlsio.HAlignType.center;
      style.vAlign = xlsio.VAlignType.center;
      style.bold = true;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
    }

    final businessInfoStyle = sheet.getRangeByIndex(1, 1).cellStyle;
    businessInfoStyle.fontName = 'Times New Roman';
    businessInfoStyle.fontSize = 12;
    businessInfoStyle.bold = true;
    businessInfoStyle.wrapText = true;
    businessInfoStyle.vAlign = xlsio.VAlignType.center;
    businessInfoStyle.hAlign = xlsio.HAlignType.left;

    final titleStyle = sheet.getRangeByIndex(5, 1).cellStyle;
    titleStyle.fontName = 'Times New Roman';
    titleStyle.fontSize = 12;
    titleStyle.bold = true;
    titleStyle.hAlign = xlsio.HAlignType.center;
    titleStyle.vAlign = xlsio.VAlignType.center;

    final noteStyle = sheet.getRangeByIndex(1, 4).cellStyle;
    noteStyle.fontName = 'Times New Roman';
    noteStyle.fontSize = 12;
    noteStyle.wrapText = true;
    noteStyle.hAlign = xlsio.HAlignType.center;
    noteStyle.vAlign = xlsio.VAlignType.top;

    final locationStyle = sheet.getRangeByIndex(6, 1).cellStyle;
    locationStyle.fontName = 'Times New Roman';
    locationStyle.fontSize = 12;
    locationStyle.hAlign = xlsio.HAlignType.center;

    final periodStyle = sheet.getRangeByIndex(7, 1).cellStyle;
    periodStyle.fontName = 'Times New Roman';
    periodStyle.fontSize = 12;
    periodStyle.hAlign = xlsio.HAlignType.center;
  }

  static void _writeBusinessInfo(
    xlsio.Worksheet sheet, {
    required String businessName,
    required String taxCode,
    required String address,
  }) {
    _setText(
      sheet,
      0,
      0,
      'HỘ, CÁ NHÂN KINH DOANH: ${businessName.trim()}\nMã số thuế: ${taxCode.trim()}\nĐịa chỉ: ${address.trim()}',
    );
    final style = _cell(sheet, 0, 0).cellStyle;
    style.fontName = 'Times New Roman';
    style.fontSize = 12;
    style.bold = true;
    style.wrapText = true;
    style.vAlign = xlsio.VAlignType.center;
  }

  static void _writeLabel(
    xlsio.Worksheet sheet, {
    required int row,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) return;
    final range = _cell(sheet, row, 0);
    final existing = range.text ?? '';
    final colonIndex = existing.indexOf(':');
    if (colonIndex >= 0) {
      range.setText('${existing.substring(0, colonIndex + 1)} ${value.trim()}');
    } else {
      range.setText('$label: ${value.trim()}');
    }
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.hAlign = xlsio.HAlignType.center;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
  }

  static int _writeSummaryRows(xlsio.Worksheet sheet, _S2cSummaryData summary) {
    final revenueTotalRow = 10;
    _writeSummaryLabel(
      sheet,
      row: revenueTotalRow,
      label: '1. Doanh thu bán hàng hóa, dịch vụ',
      bold: true,
    );
    _writeAmountOrPlaceholder(
      sheet,
      row: revenueTotalRow,
      value: summary.revenueTotal,
      placeholder: '',
      bold: true,
    );

    var currentRow = revenueTotalRow + 1;
    currentRow = _writeGroupedEntries(sheet, currentRow, summary.revenueGroups);

    final costTotalRow = currentRow;
    _writeSummaryLabel(
      sheet,
      row: costTotalRow,
      label: '2. Chi phí hợp lý',
      bold: true,
    );
    _writeAmountOrPlaceholder(
      sheet,
      row: costTotalRow,
      value: summary.costTotal,
      placeholder: '',
      bold: true,
    );

    currentRow = _writeGroupedEntries(
      sheet,
      costTotalRow + 1,
      summary.costGroups,
    );

    _writeSummaryLabel(
      sheet,
      row: currentRow,
      label: '3. Chênh lệch {(3) = (1) - (2)}',
      bold: true,
    );
    _writeFormulaOrAmountCell(
      sheet,
      row: currentRow,
      value: summary.difference,
      formula: '=D${revenueTotalRow + 1}-D${costTotalRow + 1}',
    );
    currentRow++;

    _writeSummaryLabel(
      sheet,
      row: currentRow,
      label: '4. Thuế TNCN phải nộp',
      bold: true,
    );
    _writeAmountOrPlaceholder(
      sheet,
      row: currentRow,
      value: summary.pitTax,
      placeholder: '',
      bold: true,
    );

    return currentRow + 2;
  }

  static int _writeGroupedEntries(
    xlsio.Worksheet sheet,
    int startRow,
    List<_S2cIndustryGroup> groups,
  ) {
    var currentRow = startRow;
    for (final group in groups) {
      if (!_isStructuralSummaryLabel(group.label)) {
        _writeIndustryHeader(sheet, row: currentRow, label: group.label);
        currentRow++;
      }
      for (final entry in group.entries) {
        _writeDetailRow(sheet, row: currentRow, entry: entry);
        currentRow++;
      }
    }
    return currentRow;
  }

  static bool _isStructuralSummaryLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized.contains('doanh thu') || normalized.contains('chi phí');
  }

  static void _writeIndustryHeader(
    xlsio.Worksheet sheet, {
    required int row,
    required String label,
  }) {
    _applyRowStyle(sheet, row);
    _clearRow(sheet, row);
    final range = sheet.getRangeByIndex(row + 1, 3);
    range.setText(label);
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.bold = true;
    range.cellStyle.italic = true;
    range.cellStyle.hAlign = xlsio.HAlignType.left;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
  }

  static void _writeDetailRow(
    xlsio.Worksheet sheet, {
    required int row,
    required _S2cEntry entry,
  }) {
    _applyRowStyle(sheet, row);
    _clearRow(sheet, row);

    final codeRange = sheet.getRangeByIndex(row + 1, 1);
    codeRange.setText(entry.code);
    codeRange.cellStyle.fontName = 'Times New Roman';
    codeRange.cellStyle.fontSize = 12;
    codeRange.cellStyle.hAlign = xlsio.HAlignType.left;

    if (entry.date != null) {
      final dateRange = sheet.getRangeByIndex(row + 1, 2);
      dateRange.setText(_fmtDisplayDate(entry.date!));
      dateRange.cellStyle.fontName = 'Times New Roman';
      dateRange.cellStyle.fontSize = 12;
      dateRange.cellStyle.hAlign = xlsio.HAlignType.center;
      dateRange.cellStyle.vAlign = xlsio.VAlignType.center;
    }

    final noteRange = sheet.getRangeByIndex(row + 1, 3);
    noteRange.setText(entry.note);
    noteRange.cellStyle.fontName = 'Times New Roman';
    noteRange.cellStyle.fontSize = 12;
    noteRange.cellStyle.wrapText = true;
    noteRange.cellStyle.hAlign = xlsio.HAlignType.left;
    noteRange.cellStyle.vAlign = xlsio.VAlignType.center;

    _writeAmountOrPlaceholder(
      sheet,
      row: row,
      value: entry.amount,
      placeholder: '',
    );
  }

  static void _writeSummaryLabel(
    xlsio.Worksheet sheet, {
    required int row,
    required String label,
    DateTime? date,
    bool bold = false,
  }) {
    _applyRowStyle(sheet, row);
    _clearRow(sheet, row);
    if (date != null) {
      final dateRange = sheet.getRangeByIndex(row + 1, 2);
      dateRange.setText(_fmtDisplayDate(date));
      dateRange.cellStyle.fontName = 'Times New Roman';
      dateRange.cellStyle.fontSize = 12;
      dateRange.cellStyle.hAlign = xlsio.HAlignType.center;
      dateRange.cellStyle.vAlign = xlsio.VAlignType.center;
    }
    final range = sheet.getRangeByIndex(row + 1, 3);
    range.setText(label);
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.wrapText = true;
    range.cellStyle.hAlign = xlsio.HAlignType.left;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
    range.cellStyle.bold = bold;
  }

  static void _writeAmountOrPlaceholder(
    xlsio.Worksheet sheet, {
    required int row,
    required num? value,
    required String placeholder,
    bool bold = false,
  }) {
    final range = sheet.getRangeByIndex(row + 1, 4);
    if (value != null) {
      range.setNumber(value.toDouble());
      range.numberFormat = value == value.roundToDouble()
          ? '#,##0'
          : '#,##0.00';
    } else {
      range.setText(placeholder);
    }
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.wrapText = true;
    range.cellStyle.hAlign = value != null
        ? xlsio.HAlignType.right
        : xlsio.HAlignType.left;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
    range.cellStyle.bold = bold;
  }

  static void _writeFormulaOrAmountCell(
    xlsio.Worksheet sheet, {
    required int row,
    required num? value,
    required String formula,
  }) {
    final range = sheet.getRangeByIndex(row + 1, 4);
    if (value != null) {
      range.setNumber(value.toDouble());
      range.numberFormat = value == value.roundToDouble()
          ? '#,##0'
          : '#,##0.00';
    } else {
      range.setText(formula.replaceFirst('=', ''));
    }
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.hAlign = xlsio.HAlignType.right;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
    range.cellStyle.bold = true;
  }

  static void _applyRowStyle(xlsio.Worksheet sheet, int row) {
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 12;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
      style.hAlign = c == 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
      style.vAlign = xlsio.VAlignType.center;
      style.wrapText = true;
    }
  }

  static void _applyHeaderRowStyle(
    xlsio.Worksheet sheet, {
    required int row,
    required double fontSize,
  }) {
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = fontSize;
      style.hAlign = xlsio.HAlignType.center;
      style.vAlign = xlsio.VAlignType.center;
      style.bold = true;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
    }
  }

  static void _writeSignatureBlock(
    xlsio.Worksheet sheet, {
    required int startRow,
  }) {
    _setText(sheet, startRow, 3, 'Ngày ... tháng ... năm ...');
    _setText(sheet, startRow + 1, 3, 'NGƯỜI ĐẠI DIỆN HỘ KINH DOANH/');
    _setText(sheet, startRow + 2, 3, 'CÁ NHÂN KINH DOANH');
    _setText(
      sheet,
      startRow + 3,
      3,
      '(Ký, ghi rõ họ tên và đóng dấu (nếu có))',
    );

    for (var i = 0; i < 4; i++) {
      final style = _cell(sheet, startRow + i, 3).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 12;
      style.hAlign = xlsio.HAlignType.center;
      style.vAlign = xlsio.VAlignType.center;
      style.bold = i == 1 || i == 2;
      if (i == 0 || i == 3) {
        style.italic = true;
      }
    }
  }

  static void _clearRow(xlsio.Worksheet sheet, int row) {
    for (var c = 0; c < _columns; c++) {
      _setText(sheet, row, c, '');
    }
  }

  static xlsio.Range _cell(xlsio.Worksheet sheet, int row, int col) {
    return sheet.getRangeByIndex(row + 1, col + 1);
  }

  static void _setText(xlsio.Worksheet sheet, int row, int col, String text) {
    _cell(sheet, row, col).setText(text);
  }

  static dynamic _pick(
    Map<String, dynamic> row,
    String primary,
    List<String> aliases,
  ) {
    final v = row[primary];
    if (v != null && v.toString().trim().isNotEmpty) return v;
    for (final a in aliases) {
      final x = row[a];
      if (x != null && x.toString().trim().isNotEmpty) return x;
    }
    return null;
  }

  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value.replaceAll(',', '').trim());
    return num.tryParse(value.toString());
  }

  static num? _sumSectionAmounts(
    List<Map<String, dynamic>> dataRows,
    String section,
  ) {
    num sum = 0;
    var hasValue = false;
    for (final row in dataRows) {
      final rowSection = _inferSection(row)?.trim().toLowerCase();
      if (rowSection != section) continue;
      final value = _toNum(_pick(row, 'so_tien', _amountAliases));
      if (value == null) continue;
      sum += value;
      hasValue = true;
    }
    return hasValue ? sum : null;
  }

  static String? _inferSection(Map<String, dynamic> row) {
    const keys = ['section', 'Section', 'sectionType', 'kind', 'type'];
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static List<_S2cIndustryGroup> _buildEntryGroups(
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData, {
    required String sectionFilter,
  }) {
    // Only use sections-based grouping when sections have per-industry structure
    // (businessTypeName populated per section — S2a/S2b per_group pattern).
    // S2c uses per_section path: sections are structural blocks without
    // per-industry businessTypeName, so fall through to dataRows grouping.
    final matchingSections =
        sectionsData?.sections.where((s) {
          final st = s.sectionType.trim().toLowerCase();
          if (st == sectionFilter) return true;
          if (st == 'revenue_cost') {
            final groupKey = s.businessTypeId?.trim().toLowerCase();
            return groupKey == sectionFilter;
          }
          return false;
        }).toList() ??
        [];

    final hasIndustryStructure = matchingSections.any(
      (s) => s.businessTypeName?.trim().isNotEmpty == true,
    );

    final isRevenueCostStructure = matchingSections.any(
      (s) => s.sectionType.trim().toLowerCase() == 'revenue_cost',
    );

    // In S2c, revenue_cost sections are structural blocks, not industry groups.
    // Group details from row data to avoid duplicate headers like I/II.
    if (isRevenueCostStructure) {
      return _buildGroupsFromDataRows(dataRows, sectionsData, sectionFilter);
    }

    if (matchingSections.isNotEmpty && hasIndustryStructure) {
      return _buildGroupsFromSections(dataRows, matchingSections);
    }

    // Also check all sections in case sectionType is not explicitly labelled.
    if (sectionFilter == 'revenue') {
      final allWithIndustry = (sectionsData?.sections ?? [])
          .where((s) => s.businessTypeName?.trim().isNotEmpty == true)
          .toList();
      if (allWithIndustry.isNotEmpty) {
        return _buildGroupsFromSections(dataRows, allWithIndustry);
      }

      // Requirement: revenue detail is shown only when revenue sections exist.
      // If revenue sections are not ready yet, keep only the summary row.
      return const [];
    }

    return _buildGroupsFromDataRows(dataRows, sectionsData, sectionFilter);
  }

  static List<_S2cIndustryGroup> _buildGroupsFromSections(
    List<Map<String, dynamic>> dataRows,
    List<BookSectionResponseDto> sections,
  ) {
    final result = <_S2cIndustryGroup>[];
    final sorted = [...sections]
      ..sort((a, b) => a.groupIndex.compareTo(b.groupIndex));

    for (final section in sorted) {
      final groupLabel = (section.businessTypeName?.trim().isNotEmpty == true)
          ? section.businessTypeName!
          : 'Ngành nghề';

      final entries = <_S2cEntry>[];
      for (final row in section.rows) {
        if (row.lineType.trim().toLowerCase() != 'data_placeholder') continue;
        final btFilter = row.businessTypeId ?? section.businessTypeId;
        final sectionFilter =
            row.section?.trim().toLowerCase() ?? section.sectionType.trim().toLowerCase();
        final matching =
            dataRows.where((dataRow) {
              final rowSection = _inferSection(dataRow)?.trim().toLowerCase();
              if (sectionFilter.isNotEmpty &&
                  sectionFilter != 'revenue_cost' &&
                  rowSection != sectionFilter) {
                return false;
              }
              if (btFilter == null || btFilter.isEmpty) return true;
              final dataBt = dataRow['businessTypeId']?.toString();
              return dataBt == btFilter || rowSection == btFilter.toLowerCase();
            }).toList()..sort((a, b) {
              final da = _parseDate(_pick(a, 'ngay_thang', _dateAliases));
              final db = _parseDate(_pick(b, 'ngay_thang', _dateAliases));
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });

        for (final dataRow in matching) {
          final amount = _toNum(_pick(dataRow, 'so_tien', _amountAliases));
          final rawNote =
              _pick(dataRow, 'dien_giai', _descAliases)?.toString().trim() ??
              '';
          if (amount == null || rawNote.isEmpty) continue;
          entries.add(
            _S2cEntry(
              code: _pick(dataRow, 'so_hieu', _codeAliases)?.toString() ?? '',
              note: rawNote,
              amount: amount,
              date: _parseDate(_pick(dataRow, 'ngay_thang', _dateAliases)),
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

  static List<_S2cIndustryGroup> _buildGroupsFromDataRows(
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData,
    String sectionFilter,
  ) {
    final seeds = _buildIndustrySeeds(sectionsData);
    final groups = <String, _PendingIndustryGroup>{};

    final matchingRows =
        dataRows.where((row) {
          final rowSection = _inferSection(row)?.trim().toLowerCase();
          final isCostLike = _pick(row, 'CostType', _costHints) != null;
          if (sectionFilter == 'revenue') {
            // Revenue rows are either explicitly tagged 'revenue' or have no section
            // tag at all (raw transaction data from the /rows API).
            final isRevenueShape =
                rowSection == 'revenue' ||
                rowSection == null ||
                rowSection.isEmpty;
            return isRevenueShape && !isCostLike;
          }
          return rowSection == sectionFilter || isCostLike;
        }).toList()..sort((a, b) {
          final da = _parseDate(_pick(a, 'ngay_thang', _dateAliases));
          final db = _parseDate(_pick(b, 'ngay_thang', _dateAliases));
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

    for (final row in matchingRows) {
      final amount = _toNum(_pick(row, 'so_tien', _amountAliases));
      final rawNote =
          _pick(row, 'dien_giai', _descAliases)?.toString().trim() ?? '';
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
          code: _pick(row, 'so_hieu', _codeAliases)?.toString() ?? '',
          note: _normalizeNoteForGroup(rawNote, industry.label),
          amount: amount,
          date: _parseDate(_pick(row, 'ngay_thang', _dateAliases)),
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

  static Map<String, _IndustrySeed> _buildIndustrySeeds(
    BookSectionsResponse? sectionsData,
  ) {
    final seeds = <String, _IndustrySeed>{};
    final sections = [...?sectionsData?.sections]
      ..sort((a, b) => a.groupIndex.compareTo(b.groupIndex));
    for (final section in sections) {
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

  static _ResolvedIndustry _resolveIndustry(
    Map<String, dynamic> row,
    String rawNote,
    Map<String, _IndustrySeed> seeds,
  ) {
    final businessTypeId = _pick(
      row,
      'businessTypeId',
      _businessTypeIdAliases,
    )?.toString().trim();
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

    final businessTypeName = _pick(
      row,
      'businessTypeName',
      _businessTypeNameAliases,
    )?.toString().trim();
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
    if (_normalizeKey(prefix) != _normalizeKey(groupLabel))
      return normalizedNote;

    final trimmed = normalizedNote.substring(colonIndex + 1).trim();
    return trimmed.isEmpty ? normalizedNote : trimmed;
  }

  static String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static num? _findAmountByKeywords(
    List<SectionRowDto> rows,
    List<String> keywords,
  ) {
    for (final row in rows) {
      final label = (row.values['dien_giai']?.toString() ?? '').toLowerCase();
      if (label.isEmpty) continue;
      final matched = keywords.any((keyword) => label.contains(keyword));
      if (!matched) continue;
      final amount = _toNum(_pick(row.values, 'so_tien', _amountAliases));
      if (amount != null) return amount;
    }
    return null;
  }

  static num? _findPitAmount(List<SectionRowDto> rows) {
    for (final row in rows) {
      final label = (row.values['dien_giai']?.toString() ?? '').toLowerCase();
      final taxType = row.taxType?.trim().toUpperCase();
      if (taxType == 'PIT' || taxType == 'TNCN' || label.contains('tncn')) {
        final amount = _toNum(_pick(row.values, 'so_tien', _amountAliases));
        if (amount != null) return amount;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static String _fmtDisplayDate(DateTime value) {
    return DateFormatter.formatDate(value);
  }

  static Future<File?> _save(
    xlsio.Workbook workbook,
    String displayName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = displayName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    var file = File('${dir.path}/$safe.xlsx');
    var counter = 1;
    while (await file.exists()) {
      file = File('${dir.path}/$safe ($counter).xlsx');
      counter++;
    }
    final bytes = workbook.saveAsStream();
    final patchedBytes = _applyS2cHeaderRichText(bytes);
    await file.writeAsBytes(patchedBytes, flush: true);
    return file;
  }

  static List<int> _applyS2cHeaderRichText(List<int> xlsxBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);
      final sharedStringsIndex = archive.files.indexWhere(
        (f) => f.name == 'xl/sharedStrings.xml',
      );
      if (sharedStringsIndex < 0) return xlsxBytes;

      final sharedStringsFile = archive.files[sharedStringsIndex];
      final contentBytes = _toBytes(sharedStringsFile.content);
      if (contentBytes == null || contentBytes.isEmpty) return xlsxBytes;

      var xml = utf8.decode(contentBytes, allowMalformed: true);

      const plainValue =
          'Mẫu số S2c-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)';
      final escapedPlainValue = _escapeXml(plainValue);
      const firstLine = 'Mẫu số S2c-HKD';
      const secondLine =
          '(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)';

      final richSi =
          '<si>'
          '<r>'
          '<rPr><b/><sz val="12"/><rFont val="Times New Roman"/><family val="2"/><charset val="0"/></rPr>'
          '<t>${_escapeXml(firstLine)}</t>'
          '</r>'
          '<r>'
          '<rPr><sz val="12"/><rFont val="Times New Roman"/><family val="2"/><charset val="0"/></rPr>'
          '<t xml:space="preserve">\n${_escapeXml(secondLine)}</t>'
          '</r>'
          '</si>';

      final plainSi = '<si><t>$escapedPlainValue</t></si>';
      final plainSiPreserve =
          '<si><t xml:space="preserve">$escapedPlainValue</t></si>';

      var replaced = false;
      if (xml.contains(plainSi)) {
        xml = xml.replaceFirst(plainSi, richSi);
        replaced = true;
      } else if (xml.contains(plainSiPreserve)) {
        xml = xml.replaceFirst(plainSiPreserve, richSi);
        replaced = true;
      }

      if (!replaced) return xlsxBytes;

      final updatedXmlBytes = utf8.encode(xml);
      final updatedSharedStrings = ArchiveFile(
        sharedStringsFile.name,
        updatedXmlBytes.length,
        updatedXmlBytes,
      );

      final updatedArchive = Archive();
      for (var i = 0; i < archive.files.length; i++) {
        updatedArchive.addFile(
          i == sharedStringsIndex ? updatedSharedStrings : archive.files[i],
        );
      }

      final encoded = ZipEncoder().encode(updatedArchive);
      return encoded ?? xlsxBytes;
    } catch (_) {
      return xlsxBytes;
    }
  }

  static List<int>? _toBytes(dynamic content) {
    if (content is List<int>) return content;
    if (content is String) return utf8.encode(content);
    try {
      if (content != null) {
        final asUint8 = (content as dynamic).toUint8List();
        if (asUint8 is List<int>) return asUint8;
      }
    } catch (_) {}
    return null;
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
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

  const _S2cIndustryGroup({required this.label, this.entries = const []});
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

  const _IndustrySeed({required this.label, required this.order});
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
