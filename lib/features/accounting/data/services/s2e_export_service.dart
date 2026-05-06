import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

class S2eExportService {
  const S2eExportService._();

  static const _columns =
      5; // A(Số hiệu), B(Ngày tháng), C(Diễn giải), D(Thu/Gửi vào), E(Chi/Rút ra)
  static const _fontName = 'Times New Roman';
  static const _headerFontSize = 12.0;
  static const _dataFontSize = 10.0;

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
    'ngay_thang',
    'receivedAt',
    'createdAt',
    'updatedAt',
    'documentDate',
    'date',
  ];
  static const _descAliases = [
    'dien_giai',
    'description',
    'note',
    'planName',
    'businessLocationName',
  ];
  static const _thuVaoAliases = [
    'thu_vao',
    'thuVao',
    'income',
    'amountIn',
    'deposit',
    'revenue',
    'finalAmount',
  ];
  static const _chiRaAliases = [
    'chi_ra',
    'chiRa',
    'expense',
    'amountOut',
    'withdrawal',
    'cost',
    'amount',
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
      final sheet = _ensureSheet(workbook, 'S2e');
      _buildScaffold(sheet);
      _writeBusinessInfo(
        sheet,
        businessName: businessName,
        taxCode: taxCode,
        address: address,
      );
      _writeLabel(
        sheet,
        row: 3,
        col: 0,
        label: 'Kỳ kê khai',
        value: periodLabel,
      );

      // Build rows based on sections data
      int currentRow = 8; // 0-indexed, row 9 in Excel (1-indexed)
      currentRow = _writeSectionsData(
        sheet,
        currentRow,
        dataRows,
        sectionsData,
      );

      // Signature block
      _writeSignatureBlock(sheet, currentRow + 2);

      return await _save(workbook, book.displayName);
    } catch (e, st) {
      // ignore: avoid_print
      print('S2eExportService export failed: $e\n$st');
      return null;
    } finally {
      workbook.dispose();
    }
  }

  /// Write all sections (cash + bank) following the template layout
  static int _writeSectionsData(
    xlsio.Worksheet sheet,
    int startRow,
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData,
  ) {
    int r = startRow;

    if (sectionsData != null && sectionsData.sections.isNotEmpty) {
      for (final section in sectionsData.sections) {
        for (final row in section.rows) {
          final lineType = row.lineType.trim().toLowerCase();
          switch (lineType) {
            case 'industry_header':
            case 'section_header':
              // Bold section title like "Tiền mặt" or "Tiền gửi không kỳ hạn"
              _writeSectionHeader(
                sheet,
                r,
                row.values['dien_giai']?.toString() ??
                    section.businessTypeName ??
                    '',
              );
              r++;
              break;
            case 'bank_header':
              // Italic bank name like "Ngân hàng..."
              _writeBankHeader(
                sheet,
                r,
                row.values['dien_giai']?.toString() ?? '',
              );
              r++;
              break;
            case 'data_placeholder':
              // Insert matching data rows
              final btFilter = row.businessTypeId ?? section.businessTypeId;
              final sFilter = row.section;
              final matching = dataRows.where((dr) {
                if (btFilter != null && btFilter.isNotEmpty) {
                  // Backend rows for S2e usually have section=cash/bank and
                  // businessTypeId=null, while section metadata stores cash/bank
                  // in businessTypeId. Accept either field for matching.
                  final btMatch = dr['businessTypeId']?.toString() == btFilter;
                  final sectionMatch = dr['section']?.toString() == btFilter;
                  if (!btMatch && !sectionMatch) return false;
                }
                if (sFilter != null && sFilter.isNotEmpty) {
                  return dr['section']?.toString() == sFilter;
                }
                return true;
              }).toList()..sort((a, b) {
                final da = _parseDate(_pick(a, 'ngay_thang', _dateAliases));
                final db = _parseDate(_pick(b, 'ngay_thang', _dateAliases));
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return da.compareTo(db);
              });
              for (final dataRow in matching) {
                _writeDataRow(sheet, r, dataRow);
                r++;
              }
              break;
            case 'data':
              _writeDataRow(sheet, r, row.values);
              r++;
              break;
            case 'subtotal':
            case 'total':
              _writeSummaryRow(sheet, r, row.values);
              r++;
              break;
            default:
              // Generic row - write description and amounts
              _writeGenericRow(sheet, r, row.values);
              r++;
              break;
          }
        }
      }

      // Footer rows
      for (final row in sectionsData.footerRows) {
        _writeSummaryRow(sheet, r, row.values);
        r++;
      }
    } else {
      // No sections data - write flat data rows with basic cash section
      _writeSectionHeader(sheet, r, 'Tiền mặt');
      r++;
      _writeSummaryLabel(sheet, r, 'Tiền mặt đầu kỳ');
      r++;

      for (final row in dataRows) {
        _writeDataRow(sheet, r, row);
        r++;
      }
      r++; // empty row

      _writeSummaryLabel(sheet, r, 'Tổng tiền thu vào trong kỳ');
      _setAmount(sheet, r, 3, _sumColumn(dataRows, 'thu_vao', _thuVaoAliases));
      r++;
      _writeSummaryLabel(sheet, r, 'Tổng tiền chi ra trong kỳ');
      _setAmount(sheet, r, 4, _sumColumn(dataRows, 'chi_ra', _chiRaAliases));
      r++;
      _writeSummaryLabel(sheet, r, 'Tiền mặt tồn cuối kỳ');
      r++;
    }

    return r;
  }

  // ─── Scaffold ────────────────────────────────────────────────────────

  static xlsio.Worksheet _ensureSheet(xlsio.Workbook workbook, String name) {
    if (workbook.worksheets.count > 0) {
      final s = workbook.worksheets[0];
      s.name = name;
      return s;
    }
    return workbook.worksheets.addWithName(name);
  }

  static void _buildScaffold(xlsio.Worksheet sheet) {
    // Column widths: A(Số hiệu), B(Ngày tháng), C(Diễn giải), D(Thu/Gửi vào), E(Chi/Rút ra)
    sheet.getRangeByIndex(1, 1).columnWidth = 14;
    sheet.getRangeByIndex(1, 2).columnWidth = 14;
    sheet.getRangeByIndex(1, 3).columnWidth = 48;
    sheet.getRangeByIndex(1, 4).columnWidth = 18;
    sheet.getRangeByIndex(1, 5).columnWidth = 18;

    // Row 1: Business info (cols A-C merged) + Template note (cols D-E merged)
    sheet.getRangeByIndex(1, 1, 1, 3).merge();
    sheet.getRangeByIndex(1, 4, 1, 5).merge();
    sheet.getRangeByIndex(1, 1).rowHeight = 72;

    _writeText(
      sheet,
      0,
      0,
      'HỘ, CÁ NHÂN KINH DOANH:......\nMã số thuế:.......................................\nĐịa chỉ:...........................................',
    );
    _styleCell(
      sheet,
      0,
      0,
      bold: true,
      wrapText: true,
      hAlign: xlsio.HAlignType.left,
    );

    _writeText(
      sheet,
      0,
      3,
      'Mẫu số S2e-HKD\n(Kèm theo Thông tư số\n152/2025/TT-BTC ngày 31 tháng\n12 năm 2025 của Bộ trưởng Bộ Tài\nchính)',
    );
    _styleCell(
      sheet,
      0,
      3,
      bold: false,
      italic: true,
      wrapText: true,
      hAlign: xlsio.HAlignType.center,
    );

    // Row 2: empty

    // Row 3: Title "SỔ CHI TIẾT TIỀN" (merged A-E)
    sheet.getRangeByIndex(3, 1, 3, 5).merge();
    _writeText(sheet, 2, 0, 'SỔ CHI TIẾT TIỀN');
    _styleCell(
      sheet,
      2,
      0,
      bold: true,
      hAlign: xlsio.HAlignType.center,
      fontSize: 14,
    );

    // Row 4: "Kỳ kê khai: ..." (merged A-E)
    sheet.getRangeByIndex(4, 1, 4, 5).merge();
    _writeText(sheet, 3, 0, 'Kỳ kê khai: ..................');
    _styleCell(sheet, 3, 0, italic: true, hAlign: xlsio.HAlignType.center);

    // Row 5: "Đơn vị tính: ..." (right-aligned in col D-E area)
    sheet.getRangeByIndex(5, 4, 5, 5).merge();
    _writeText(sheet, 4, 3, 'Đơn vị tính:......');
    _styleCell(sheet, 4, 3, italic: true, hAlign: xlsio.HAlignType.right);

    // Row 6: Header row 1 - "Chứng từ" (A-B merged) | "Diễn giải" (C) | "Số tiền" (D-E merged)
    sheet.getRangeByIndex(6, 1, 6, 2).merge();
    sheet.getRangeByIndex(6, 4, 6, 5).merge();
    // Merge "Diễn giải" vertically (rows 6-7)
    sheet.getRangeByIndex(6, 3, 7, 3).merge();

    _writeText(sheet, 5, 0, 'Chứng từ');
    _writeText(sheet, 5, 2, 'Diễn giải');
    _writeText(sheet, 5, 3, 'Số tiền');
    _styleTableHeader(sheet, 5, 0);
    _styleTableHeader(sheet, 5, 1);
    _styleTableHeader(sheet, 5, 2);
    _styleTableHeader(sheet, 5, 3);
    _styleTableHeader(sheet, 5, 4);

    // Row 7: Header row 2 - "Số hiệu" | "Ngày tháng" | (Diễn giải merged) | "Thu/Gửi vào" | "Chi/Rút ra"
    _writeText(sheet, 6, 0, 'Số hiệu');
    _writeText(sheet, 6, 1, 'Ngày\ntháng');
    _writeText(sheet, 6, 3, 'Thu/Gửi vào');
    _writeText(sheet, 6, 4, 'Chi/Rút ra');
    _styleTableHeader(sheet, 6, 0);
    _styleTableHeader(sheet, 6, 1, wrapText: true);
    _styleTableHeader(sheet, 6, 2);
    _styleTableHeader(sheet, 6, 3);
    _styleTableHeader(sheet, 6, 4);

    // Row 8: Column markers "A", "B", "C", "1", "2"
    const markers = ['A', 'B', 'C', '1', '2'];
    for (var c = 0; c < markers.length; c++) {
      _writeText(sheet, 7, c, markers[c]);
      _styleTableHeader(sheet, 7, c, fontSize: 10);
    }
  }

  // ─── Business Info ───────────────────────────────────────────────────

  static void _writeBusinessInfo(
    xlsio.Worksheet sheet, {
    required String businessName,
    required String taxCode,
    required String address,
  }) {
    _writeText(
      sheet,
      0,
      0,
      'HỘ, CÁ NHÂN KINH DOANH: ${businessName.trim()}\nMã số thuế: ${taxCode.trim()}\nĐịa chỉ: ${address.trim()}',
    );
    _styleCell(
      sheet,
      0,
      0,
      bold: true,
      wrapText: true,
      hAlign: xlsio.HAlignType.left,
    );
  }

  static void _writeLabel(
    xlsio.Worksheet sheet, {
    required int row,
    required int col,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) return;
    final range = _cell(sheet, row, col);
    final existing = range.text ?? '';
    final colonIndex = existing.indexOf(':');
    if (colonIndex >= 0) {
      range.setText('${existing.substring(0, colonIndex + 1)} ${value.trim()}');
    } else {
      range.setText('$label: ${value.trim()}');
    }
    _styleCell(sheet, row, col, italic: true, hAlign: xlsio.HAlignType.center);
  }

  // ─── Section / Row Writers ──────────────────────────────────────────

  /// Write a bold section header like "Tiền mặt" or "Tiền gửi không kỳ hạn"
  static void _writeSectionHeader(
    xlsio.Worksheet sheet,
    int row,
    String label,
  ) {
    _applyRowBorders(sheet, row);
    _writeText(sheet, row, 2, label);
    final style = _cell(sheet, row, 2).cellStyle;
    style.bold = true;
    style.fontName = _fontName;
    style.fontSize = _dataFontSize;
  }

  /// Write a bold italic bank header like "Ngân hàng..."
  static void _writeBankHeader(xlsio.Worksheet sheet, int row, String label) {
    _applyRowBorders(sheet, row);
    _writeText(sheet, row, 2, label);
    final style = _cell(sheet, row, 2).cellStyle;
    style.bold = true;
    style.italic = true;
    style.fontName = _fontName;
    style.fontSize = _dataFontSize;
  }

  /// Write a data row with all columns
  static void _writeDataRow(
    xlsio.Worksheet sheet,
    int row,
    Map<String, dynamic> data,
  ) {
    _applyRowBorders(sheet, row);
    _writeText(
      sheet,
      row,
      0,
      _pick(data, 'so_hieu', _soHieuAliases)?.toString() ?? '',
    );
    _writeText(
      sheet,
      row,
      1,
      _fmtDate(_pick(data, 'ngay_thang', _dateAliases)),
    );
    _writeText(
      sheet,
      row,
      2,
      _pick(data, 'dien_giai', _descAliases)?.toString() ?? '',
    );
    _setAmount(sheet, row, 3, _pick(data, 'thu_vao', _thuVaoAliases));
    _setAmount(sheet, row, 4, _pick(data, 'chi_ra', _chiRaAliases));

    // Style data cells
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = _fontName;
      style.fontSize = _dataFontSize;
      style.vAlign = xlsio.VAlignType.center;
      style.hAlign = c >= 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
    }
  }

  /// Write a summary/subtotal/total row
  static void _writeSummaryRow(
    xlsio.Worksheet sheet,
    int row,
    Map<String, dynamic> values,
  ) {
    _applyRowBorders(sheet, row);
    final desc = _pick(values, 'dien_giai', _descAliases)?.toString() ?? '';
    _writeText(sheet, row, 2, desc);
    _setAmount(sheet, row, 3, _pick(values, 'thu_vao', _thuVaoAliases));
    _setAmount(sheet, row, 4, _pick(values, 'chi_ra', _chiRaAliases));

    // Bold style for summary rows
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = _fontName;
      style.fontSize = _dataFontSize;
      style.bold = true;
      style.vAlign = xlsio.VAlignType.center;
      style.hAlign = c >= 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
    }
  }

  /// Write a bold label in the Diễn giải column only
  static void _writeSummaryLabel(xlsio.Worksheet sheet, int row, String label) {
    _applyRowBorders(sheet, row);
    _writeText(sheet, row, 2, label);
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = _fontName;
      style.fontSize = _dataFontSize;
      style.bold = true;
      style.vAlign = xlsio.VAlignType.center;
      style.hAlign = c >= 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
    }
  }

  /// Write generic row (description + amounts if present)
  static void _writeGenericRow(
    xlsio.Worksheet sheet,
    int row,
    Map<String, dynamic> values,
  ) {
    _applyRowBorders(sheet, row);
    final desc = values['dien_giai']?.toString() ?? '';
    _writeText(sheet, row, 2, desc);
    _setAmount(sheet, row, 3, _pick(values, 'thu_vao', _thuVaoAliases));
    _setAmount(sheet, row, 4, _pick(values, 'chi_ra', _chiRaAliases));
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = _fontName;
      style.fontSize = _dataFontSize;
      style.vAlign = xlsio.VAlignType.center;
      style.hAlign = c >= 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
    }
  }

  // ─── Signature Block ────────────────────────────────────────────────

  static void _writeSignatureBlock(xlsio.Worksheet sheet, int startRow) {
    // Merge D-E for signature lines
    for (var i = 0; i < 4; i++) {
      sheet.getRangeByIndex(startRow + i + 1, 4, startRow + i + 1, 5).merge();
    }

    _writeText(sheet, startRow, 3, 'Ngày ... tháng ... năm ...');
    _styleCell(
      sheet,
      startRow,
      3,
      italic: true,
      hAlign: xlsio.HAlignType.center,
    );

    _writeText(sheet, startRow + 1, 3, 'NGƯỜI ĐẠI DIỆN HỘ KINH DOANH/');
    _styleCell(
      sheet,
      startRow + 1,
      3,
      bold: true,
      hAlign: xlsio.HAlignType.center,
    );

    _writeText(sheet, startRow + 2, 3, 'CÁ NHÂN KINH DOANH');
    _styleCell(
      sheet,
      startRow + 2,
      3,
      bold: true,
      hAlign: xlsio.HAlignType.center,
    );

    _writeText(sheet, startRow + 3, 3, '(Ký, họ tên, đóng dấu)');
    _styleCell(
      sheet,
      startRow + 3,
      3,
      italic: true,
      hAlign: xlsio.HAlignType.center,
    );
  }

  // ─── Cell Helpers ────────────────────────────────────────────────────

  static xlsio.Range _cell(xlsio.Worksheet sheet, int row, int col) {
    return sheet.getRangeByIndex(row + 1, col + 1);
  }

  static void _writeText(xlsio.Worksheet sheet, int row, int col, String text) {
    final cell = _cell(sheet, row, col);
    cell.setText(text);
    cell.cellStyle.fontName = _fontName;
    cell.cellStyle.fontSize = _dataFontSize;
  }

  static void _setAmount(
    xlsio.Worksheet sheet,
    int row,
    int col,
    dynamic value,
  ) {
    final n = _toNum(value);
    if (n == null) {
      if (value != null && value.toString().trim().isNotEmpty) {
        _writeText(sheet, row, col, value.toString());
      }
      return;
    }
    final cell = _cell(sheet, row, col);
    cell.setNumber(n.toDouble());
    cell.numberFormat = n == n.roundToDouble() ? '#,##0' : '#,##0.00';
    cell.cellStyle.fontName = _fontName;
    cell.cellStyle.fontSize = _dataFontSize;
    cell.cellStyle.hAlign = xlsio.HAlignType.right;
  }

  static void _applyRowBorders(xlsio.Worksheet sheet, int row) {
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
    }
  }

  static void _styleTableHeader(
    xlsio.Worksheet sheet,
    int row,
    int col, {
    double fontSize = _headerFontSize,
    bool wrapText = false,
  }) {
    final style = _cell(sheet, row, col).cellStyle;
    style.fontName = _fontName;
    style.fontSize = fontSize;
    style.bold = true;
    style.hAlign = xlsio.HAlignType.center;
    style.vAlign = xlsio.VAlignType.center;
    style.borders.all.lineStyle = xlsio.LineStyle.thin;
    style.wrapText = wrapText;
  }

  static void _styleCell(
    xlsio.Worksheet sheet,
    int row,
    int col, {
    bool bold = false,
    bool italic = false,
    bool wrapText = false,
    xlsio.HAlignType? hAlign,
    double fontSize = _headerFontSize,
  }) {
    final style = _cell(sheet, row, col).cellStyle;
    style.fontName = _fontName;
    style.fontSize = fontSize;
    style.bold = bold;
    style.italic = italic;
    style.wrapText = wrapText;
    style.vAlign = xlsio.VAlignType.center;
    if (hAlign != null) style.hAlign = hAlign;
  }

  // ─── Value Helpers ──────────────────────────────────────────────────

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

  static num _sumColumn(
    List<Map<String, dynamic>> rows,
    String primary,
    List<String> aliases,
  ) {
    num total = 0;
    for (final row in rows) {
      total += _toNum(_pick(row, primary, aliases)) ?? 0;
    }
    return total;
  }

  static String _fmtDate(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.isEmpty) return '';
    if (value is DateTime) {
      return DateFormatter.formatDate(value);
    }
    if (value is String && value.isNotEmpty) {
      final date = DateTime.tryParse(value);
      if (date != null) {
        return DateFormatter.formatDate(date);
      }
      return s;
    }
    return value.toString();
  }

  // ─── Save ───────────────────────────────────────────────────────────

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
    final patchedBytes = _applyS2eHeaderRichText(bytes);
    await file.writeAsBytes(patchedBytes, flush: true);
    return file;
  }

  static List<int> _applyS2eHeaderRichText(List<int> xlsxBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);
      final sharedStringsIndex = archive.files.indexWhere(
        (f) => f.name == 'xl/sharedStrings.xml',
      );
      if (sharedStringsIndex < 0) {
        return xlsxBytes;
      }

      final sharedStringsFile = archive.files[sharedStringsIndex];
      final contentBytes = _toBytes(sharedStringsFile.content);
      if (contentBytes == null || contentBytes.isEmpty) {
        return xlsxBytes;
      }

      var xml = utf8.decode(contentBytes, allowMalformed: true);

      const firstLine = 'Mẫu số S2e-HKD';
      const secondLine =
          '(Kèm theo Thông tư số\n152/2025/TT-BTC ngày 31 tháng\n12 năm 2025 của Bộ trưởng Bộ Tài\nchính)';
      const plainValue = '$firstLine\n$secondLine';

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

      final plainSi = '<si><t>${_escapeXml(plainValue)}</t></si>';
      final plainSiPreserve =
          '<si><t xml:space="preserve">${_escapeXml(plainValue)}</t></si>';

      var replaced = false;
      if (xml.contains(plainSi)) {
        xml = xml.replaceFirst(plainSi, richSi);
        replaced = true;
      } else if (xml.contains(plainSiPreserve)) {
        xml = xml.replaceFirst(plainSiPreserve, richSi);
        replaced = true;
      }

      if (!replaced) {
        return xlsxBytes;
      }

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
