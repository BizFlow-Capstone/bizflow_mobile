import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Export service for template S1a (So chi tiet ban hang) using Syncfusion XlsIO.
class S1aExportService {
  const S1aExportService._();

  static const _dataStartRow = 10; // 0-indexed; row 11 in Excel
  static const _dataColumnCount = 3;

  static const _dateAliases = [
    'receivedAt',
    'createdAt',
    'updatedAt',
    'documentDate',
    'ngay_thang',
  ];
  static const _descAliases = [
    'note',
    'dien_giai',
    'planName',
    'businessLocationName',
    'content',
  ];
  static const _amountAliases = [
    'finalAmount',
    'totalAmount',
    'amount',
    'planPrice',
    'so_tien',
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
      final sheet = _ensureSheet(workbook);
      _buildTemplateScaffold(sheet);

      _writeBusinessInfoCell(
        sheet,
        businessName: businessName,
        taxCode: taxCode,
        address: address,
      );
      _writeLabelCell(
        sheet,
        rowIndex: 5,
        colIndex: 0,
        label: 'Địa điểm kinh doanh',
        value: locationName,
      );
      _writeLabelCell(
        sheet,
        rowIndex: 6,
        colIndex: 0,
        label: 'Kỳ kê khai',
        value: periodLabel,
      );

      final sortedRows = List<Map<String, dynamic>>.from(dataRows)
        ..sort((a, b) {
          final da = _parseDateForSort(_pick(a, 'date', _dateAliases));
          final db = _parseDateForSort(_pick(b, 'date', _dateAliases));
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

      final visibleDataRowCount = sortedRows.isEmpty ? 1 : sortedRows.length;
      for (var i = 0; i < visibleDataRowCount; i++) {
        final targetRow = _dataStartRow + i;
        _applyDataRowStyle(sheet, rowIndex: targetRow);

        if (i >= sortedRows.length) {
          _clearRow(sheet, rowIndex: targetRow, columnCount: _dataColumnCount);
          continue;
        }

        final row = sortedRows[i];
        _writeTextCell(
          sheet,
          row: targetRow,
          col: 0,
          value: _fmtDate(_pick(row, 'date', _dateAliases)),
        );
        _writeTextCell(
          sheet,
          row: targetRow,
          col: 1,
          value: _pick(row, 'description', _descAliases)?.toString() ?? '',
        );
        _writeAmountCell(
          sheet,
          row: targetRow,
          col: 2,
          value: _pick(row, 'revenue', _amountAliases),
        );
      }

      final footerRowIndex = _dataStartRow + visibleDataRowCount;
      _applyDataRowStyle(sheet, rowIndex: footerRowIndex);
      _writeTextCell(sheet, row: footerRowIndex, col: 0, value: '');
      _writeTextCell(sheet, row: footerRowIndex, col: 1, value: 'Tổng cộng');

      final totalAmount = _resolveTotalAmount(
        dataRows: sortedRows,
        sectionsData: sectionsData,
      );
      if (totalAmount != null) {
        _writeAmountCell(
          sheet,
          row: footerRowIndex,
          col: 2,
          value: totalAmount,
        );
      } else {
        _writeTextCell(sheet, row: footerRowIndex, col: 2, value: '');
      }
      _cell(sheet, footerRowIndex, 1).cellStyle.bold = true;
      _cell(sheet, footerRowIndex, 2).cellStyle.bold = true;

      _writeSignatureBlock(sheet, startRow: footerRowIndex + 2);

      return await _save(workbook, book.displayName);
    } catch (e, st) {
      // ignore: avoid_print
      print('S1aExportService: failed to export with XlsIO: $e\n$st');
      return null;
    } finally {
      workbook.dispose();
    }
  }

  static xlsio.Worksheet _ensureSheet(xlsio.Workbook workbook) {
    if (workbook.worksheets.count > 0) {
      return workbook.worksheets[0];
    }
    return workbook.worksheets.addWithName('s1a');
  }

  static void _buildTemplateScaffold(xlsio.Worksheet sheet) {
    sheet.name = 's1a';

    sheet.getRangeByIndex(1, 1, 1, 2).merge();
    sheet.getRangeByIndex(5, 1, 5, 3).merge();
    sheet.getRangeByIndex(6, 1, 6, 3).merge();
    sheet.getRangeByIndex(7, 1, 7, 3).merge();

    sheet.getRangeByIndex(1, 1).columnWidth = 14;
    sheet.getRangeByIndex(1, 2).columnWidth = 64.44140625;
    sheet.getRangeByIndex(1, 3).columnWidth = 38;

    sheet.getRangeByIndex(1, 1).rowHeight = 72.75;

    _writeTextCell(
      sheet,
      row: 0,
      col: 0,
      value: 'HỘ, CÁ NHÂN KINH DOANH:\nMã số thuế:\nĐịa chỉ:',
    );
    _writeTextCell(
      sheet,
      row: 0,
      col: 2,
      value:
          'Mẫu số S1a-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)',
    );
    _writeTextCell(
      sheet,
      row: 4,
      col: 0,
      value: 'SỔ CHI TIẾT DOANH THU BÁN HÀNG HÓA, DỊCH VỤ',
    );
    _writeTextCell(sheet, row: 5, col: 0, value: 'Địa điểm kinh doanh:');
    _writeTextCell(sheet, row: 6, col: 0, value: 'Kỳ kê khai:');

    _writeTextCell(sheet, row: 8, col: 0, value: 'Ngày tháng');
    _writeTextCell(sheet, row: 8, col: 1, value: 'Giao dịch');
    _writeTextCell(sheet, row: 8, col: 2, value: 'Số tiền');

    _writeTextCell(sheet, row: 9, col: 0, value: 'A');
    _writeTextCell(sheet, row: 9, col: 1, value: 'B');
    _writeTextCell(sheet, row: 9, col: 2, value: '1');

    _applyHeaderRowStyle(sheet, rowIndex: 8);
    _applyHeaderRowStyle(sheet, rowIndex: 9);

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

    final noteStyle = sheet.getRangeByIndex(1, 3).cellStyle;
    noteStyle.fontName = 'Times New Roman';
    noteStyle.fontSize = 12;
    noteStyle.bold = false;
    noteStyle.wrapText = true;
    noteStyle.vAlign = xlsio.VAlignType.top;
    noteStyle.hAlign = xlsio.HAlignType.center;
  }

  static void _writeBusinessInfoCell(
    xlsio.Worksheet sheet, {
    required String businessName,
    required String taxCode,
    required String address,
  }) {
    final lines = <String>[
      'HỘ, CÁ NHÂN KINH DOANH: ${businessName.trim()}',
      'Mã số thuế: ${taxCode.trim()}',
      'Địa chỉ: ${address.trim()}',
    ];
    final range = sheet.getRangeByIndex(1, 1);
    range.setText(lines.join('\n'));
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.bold = true;
    range.cellStyle.wrapText = true;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
  }

  static void _writeSignatureBlock(
    xlsio.Worksheet sheet, {
    required int startRow,
  }) {
    _writeTextCell(
      sheet,
      row: startRow,
      col: 2,
      value: 'Ngày ... tháng ... năm ...',
    );
    _writeTextCell(
      sheet,
      row: startRow + 1,
      col: 2,
      value: 'NGƯỜI ĐẠI DIỆN HỘ KINH DOANH/',
    );
    _writeTextCell(
      sheet,
      row: startRow + 2,
      col: 2,
      value: 'CÁ NHÂN KINH DOANH',
    );
    _writeTextCell(
      sheet,
      row: startRow + 3,
      col: 2,
      value: '(Ký, họ tên, đóng dấu)',
    );

    for (var i = 0; i < 4; i++) {
      final style = _cell(sheet, startRow + i, 2).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 12;
      style.hAlign = xlsio.HAlignType.center;
      style.vAlign = xlsio.VAlignType.center;
      style.bold = i == 1 || i == 2;
    }
  }

  static void _writeLabelCell(
    xlsio.Worksheet sheet, {
    required int rowIndex,
    required int colIndex,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) return;

    final range = _cell(sheet, rowIndex, colIndex);
    final existing = range.text ?? '';
    final ci = existing.indexOf(':');
    if (ci >= 0) {
      range.setText('${existing.substring(0, ci + 1)} ${value.trim()}');
      range.cellStyle.fontName = 'Times New Roman';
      range.cellStyle.fontSize = 12;
      range.cellStyle.hAlign = xlsio.HAlignType.center;
      range.cellStyle.vAlign = xlsio.VAlignType.center;
      return;
    }
    range.setText('$label: ${value.trim()}');
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.hAlign = xlsio.HAlignType.center;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
  }

  static xlsio.Range _cell(xlsio.Worksheet sheet, int row, int col) {
    return sheet.getRangeByIndex(row + 1, col + 1);
  }

  static void _writeTextCell(
    xlsio.Worksheet sheet, {
    required int row,
    required int col,
    required String value,
  }) {
    final cell = _cell(sheet, row, col);
    cell.setText(value);
    cell.cellStyle.fontName = 'Times New Roman';
    cell.cellStyle.fontSize = 12;
  }

  static void _writeAmountCell(
    xlsio.Worksheet sheet, {
    required int row,
    required int col,
    required dynamic value,
  }) {
    final range = _cell(sheet, row, col);
    final numericValue = _toNumber(value);
    if (numericValue == null) {
      range.setText(value?.toString() ?? '');
      range.cellStyle.fontName = 'Times New Roman';
      range.cellStyle.fontSize = 12;
      return;
    }

    range.setNumber(numericValue);
    range.numberFormat = numericValue == numericValue.roundToDouble()
        ? '#,##0'
        : '#,##0.00';
    range.cellStyle.hAlign = xlsio.HAlignType.right;
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
  }

  static void _applyHeaderRowStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final range = _cell(sheet, rowIndex, col);
      final style = range.cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 12;
      style.hAlign = xlsio.HAlignType.center;
      style.vAlign = xlsio.VAlignType.center;
      style.bold = true;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
    }
  }

  static void _applyDataRowStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final range = _cell(sheet, rowIndex, col);
      final style = range.cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 12;
      style.vAlign = xlsio.VAlignType.center;
      style.hAlign = col == 2 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
    }
  }

  static void _clearRow(
    xlsio.Worksheet sheet, {
    required int rowIndex,
    required int columnCount,
  }) {
    for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
      final range = _cell(sheet, rowIndex, columnIndex);
      range.setText('');
    }
  }

  static num? _resolveTotalAmount({
    required List<Map<String, dynamic>> dataRows,
    required BookSectionsResponse? sectionsData,
  }) {
    if (sectionsData != null && sectionsData.footerRows.isNotEmpty) {
      for (final footerRow in sectionsData.footerRows) {
        final total =
            _pick(footerRow.values, 'revenue', _amountAliases) ??
            _pick(footerRow.values, 'so_tien', _amountAliases);
        final numericValue = _toNumber(total);
        if (numericValue != null) return numericValue;
      }
    }

    num sum = 0;
    var hasAmount = false;
    for (final row in dataRows) {
      final numericValue = _toNumber(_pick(row, 'revenue', _amountAliases));
      if (numericValue == null) continue;
      sum += numericValue;
      hasAmount = true;
    }
    return hasAmount ? sum : null;
  }

  static double? _toNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '').trim();
      return double.tryParse(normalized);
    }
    return double.tryParse(value.toString());
  }

  static dynamic _pick(
    Map<String, dynamic> row,
    String primary,
    List<String> aliases,
  ) {
    final d = row[primary];
    if (d != null && d.toString().trim().isNotEmpty) return d;
    for (final a in aliases) {
      final v = row[a];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// Parse a value into a UTC instant for sorting.
  ///
  /// Interpretation rules:
  /// - If value is a DateTime with `isUtc == true` return it as-is.
  /// - If value is a DateTime without timezone or a string without offset,
  ///   treat the components as occurring in timezone UTC+7 and convert to UTC.
  /// - If string contains an explicit offset (e.g. Z or +07:00), parse normally
  ///   and convert to UTC.
  static DateTime? _parseDateForSort(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) {
      if (val.isUtc) return val;
      return DateTime.utc(val.year, val.month, val.day, val.hour, val.minute, val.second).subtract(const Duration(hours: 7));
    }
    final s = val.toString().trim();
    if (s.isEmpty) return null;
    // If string likely contains timezone offset or full ISO with offset, trust DateTime.parse
    final hasOffset = RegExp(r'Z$|[+-]\d{2}(:?\d{2})?\$').hasMatch(s) || s.contains('T') && RegExp(r'[+-]\d{2}:?\d{2}').hasMatch(s);
    if (hasOffset) {
      try {
        return DateTime.parse(s).toUtc();
      } catch (_) {}
    }
    // Fallback: parse components then treat as in UTC+7
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second).subtract(const Duration(hours: 7));
  }

  static String _fmtDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) {
      return DateFormatter.formatDate(val);
    }
    if (val is String && val.isNotEmpty) {
      final date = DateTime.tryParse(val);
      if (date != null) {
        return DateFormatter.formatDate(date);
      }
      return val;
    }
    return val.toString();
  }

  static Future<File?> _save(
    xlsio.Workbook workbook,
    String displayName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = displayName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    var file = File('${dir.path}/$safeName.xlsx');
    var counter = 1;
    while (await file.exists()) {
      file = File('${dir.path}/$safeName ($counter).xlsx');
      counter++;
    }

    final bytes = workbook.saveAsStream();
    final patchedBytes = _applyS1aHeaderRichText(bytes);
    await file.writeAsBytes(patchedBytes, flush: true);
    return file;
  }

  static List<int> _applyS1aHeaderRichText(List<int> xlsxBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);
      final sharedStringsIndex = archive.files.indexWhere(
        (f) => f.name == 'xl/sharedStrings.xml',
      );
      if (sharedStringsIndex < 0) {
        return xlsxBytes;
      }

      final sharedStringsFile = archive.files[sharedStringsIndex];
      final raw = sharedStringsFile.content;
      final contentBytes = _toBytes(raw);
      if (contentBytes == null || contentBytes.isEmpty) {
        return xlsxBytes;
      }

      var xml = utf8.decode(contentBytes, allowMalformed: true);

      const plainValue =
          'Mẫu số S1a-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)';
      final escapedPlainValue = _escapeXml(plainValue);
      const firstLine = 'Mẫu số S1a-HKD';
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
      if (encoded == null) {
        return xlsxBytes;
      }
      return encoded;
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
