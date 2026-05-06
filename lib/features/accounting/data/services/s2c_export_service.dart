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
    'documentNumber',
    'DocumentNumber',
    'voucherNo',
    'voucher_no',
    'so_chung_tu',
    'documentNo',
    'DocumentNo',
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
      revenueEntries: _buildFlatEntries(dataRows, sectionsData, 'revenue'),
      costEntries: _buildFlatEntries(dataRows, sectionsData, 'cost'),
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
    for (final entry in summary.revenueEntries) {
      _writeDetailRow(sheet, row: currentRow, entry: entry);
      currentRow++;
    }

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

    currentRow = costTotalRow + 1;
    for (final entry in summary.costEntries) {
      _writeDetailRow(sheet, row: currentRow, entry: entry);
      currentRow++;
    }

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

  static List<_S2cEntry> _buildFlatEntries(
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData,
    String sectionFilter,
  ) {
    final entries = <_S2cEntry>[];
    final matchingRows =
        dataRows.where((row) {
          final rowSection = _inferSection(row)?.trim().toLowerCase();
          final isCostLike = _pick(row, 'CostType', _costHints) != null;
          if (sectionFilter == 'revenue') {
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
          return db.compareTo(da); // Descending (newest first)
        });

    for (final row in matchingRows) {
      final amount = _toNum(_pick(row, 'so_tien', _amountAliases));
      final rawNote =
          _pick(row, 'dien_giai', _descAliases)?.toString().trim() ?? '';
      if (amount == null || rawNote.isEmpty) continue;
      entries.add(
        _S2cEntry(
          code: _pick(row, 'so_hieu', _codeAliases)?.toString() ?? '',
          note: rawNote,
          amount: amount,
          date: _parseDate(_pick(row, 'ngay_thang', _dateAliases)),
        ),
      );
    }

    return entries;
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
  final List<_S2cEntry> revenueEntries;
  final List<_S2cEntry> costEntries;
  final num? difference;
  final num? pitTax;

  const _S2cSummaryData({
    this.revenueTotal,
    this.costTotal,
    this.revenueEntries = const [],
    this.costEntries = const [],
    this.difference,
    this.pitTax,
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
