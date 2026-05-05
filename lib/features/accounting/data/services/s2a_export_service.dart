import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

class S2aExportService {
  const S2aExportService._();

  static const _dataStartRow = 9;
  static const _dataColumnCount = 4;

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
    'receivedAt',
    'createdAt',
    'updatedAt',
    'documentDate',
    'date',
  ];
  static const _descAliases = [
    'description',
    'note',
    'planName',
    'businessLocationName',
  ];
  static const _amountAliases = [
    'revenue',
    'finalAmount',
    'totalAmount',
    'amount',
    'planPrice',
  ];

  static Future<File?> export({
    required AccountingBook book,
    required List<Map<String, dynamic>> dataRows,
    required BookSectionsResponse sectionsData,
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
        rowIndex: 3,
        colIndex: 0,
        label: 'Địa điểm kinh doanh',
        value: locationName,
      );
      _writeLabelCell(
        sheet,
        rowIndex: 4,
        colIndex: 0,
        label: 'Kỳ kê khai',
        value: periodLabel,
      );

      final exportRows = _buildExportRows(dataRows, sectionsData);
      final visibleRowCount = exportRows.isEmpty ? 1 : exportRows.length;

      for (var i = 0; i < visibleRowCount; i++) {
        final targetRow = _dataStartRow + i;

        if (i >= exportRows.length) {
          _applyBaseRowStyle(sheet, rowIndex: targetRow);
          _clearRow(sheet, rowIndex: targetRow);
          continue;
        }

        _writeExportRow(sheet, rowIndex: targetRow, row: exportRows[i]);
      }

      _writeSignatureBlock(
        sheet,
        startRow: _dataStartRow + visibleRowCount + 2,
      );

      return await _save(workbook, book.displayName);
    } catch (e, st) {
      // ignore: avoid_print
      print('S2aExportService export failed: $e\n$st');
      return null;
    } finally {
      workbook.dispose();
    }
  }

  static List<_ExportRow> _buildExportRows(
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse sectionsData,
  ) {
    if (sectionsData.sections.isEmpty) {
      final sorted = List<Map<String, dynamic>>.from(dataRows)
        ..sort((a, b) {
          final da = _parseDate(_pick(a, 'ngay_thang', _dateAliases));
          final db = _parseDate(_pick(b, 'ngay_thang', _dateAliases));
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      return sorted
          .map((row) => _ExportRow(lineType: 'data', values: row))
          .toList();
    }

    final exportRows = <_ExportRow>[];

    for (final section in sectionsData.sections) {
      exportRows.add(
        _ExportRow(
          lineType: 'industry_header',
          values: {
            'dien_giai':
                '${section.groupIndex}. ${section.businessTypeName ?? 'Ngành nghề'}',
          },
        ),
      );

      for (final row in section.rows) {
        final lineType = row.lineType.trim().toLowerCase();

        if (lineType == 'industry_header') {
          continue;
        }

        if (lineType == 'data_placeholder') {
          final filter = row.businessTypeId ?? section.businessTypeId;
          final matchingRows = dataRows.where((dataRow) {
            if (filter == null || filter.isEmpty) return true;
            return dataRow['businessTypeId']?.toString() == filter;
          }).toList()
            ..sort((a, b) {
              final da = _parseDate(_pick(a, 'ngay_thang', _dateAliases));
              final db = _parseDate(_pick(b, 'ngay_thang', _dateAliases));
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });

          for (final dataRow in matchingRows) {
            exportRows.add(_ExportRow(lineType: 'data', values: dataRow));
          }
          continue;
        }

        exportRows.add(
          _ExportRow(
            lineType: lineType,
            values: row.values,
            taxType: row.taxType,
          ),
        );
      }
    }

    for (final footerRow in sectionsData.footerRows) {
      exportRows.add(
        _ExportRow(
          lineType: footerRow.lineType.trim().toLowerCase(),
          values: footerRow.values,
          taxType: footerRow.taxType,
        ),
      );
    }

    return exportRows;
  }

  static void _writeExportRow(
    xlsio.Worksheet sheet, {
    required int rowIndex,
    required _ExportRow row,
  }) {
    _applyBaseRowStyle(sheet, rowIndex: rowIndex);
    final summaryLabel = row.values['dien_giai']?.toString() ?? '';

    switch (row.lineType) {
      case 'industry_header':
        _writeTextCell(sheet, row: rowIndex, col: 0, value: '');
        _writeTextCell(sheet, row: rowIndex, col: 1, value: '');
        _writeTextCell(
          sheet,
          row: rowIndex,
          col: 2,
          value: row.values['dien_giai']?.toString() ?? 'Ngành nghề',
        );
        _writeTextCell(sheet, row: rowIndex, col: 3, value: '');
        _applyIndustryHeaderStyle(sheet, rowIndex: rowIndex);
        return;

      case 'subtotal':
        _writeTextCell(sheet, row: rowIndex, col: 0, value: '');
        _writeTextCell(sheet, row: rowIndex, col: 1, value: '');
        _writeTextCell(
          sheet,
          row: rowIndex,
          col: 2,
          value: row.values['dien_giai']?.toString() ?? 'Tổng cộng',
        );
        _writeAmountCell(
          sheet,
          row: rowIndex,
          col: 3,
          value: _pickAmount(row.values),
        );
        if (_isGrandTaxTotalLabel(summaryLabel)) {
          _applyFooterStyle(sheet, rowIndex: rowIndex);
        } else {
          _applySubtotalStyle(sheet, rowIndex: rowIndex);
        }
        return;

      case 'tax':
      case 'tax_line':
        final taxLabel =
            row.values['dien_giai']?.toString() ?? row.taxType ?? 'Thuế';
        _writeTextCell(sheet, row: rowIndex, col: 0, value: '');
        _writeTextCell(sheet, row: rowIndex, col: 1, value: '');
        _writeTextCell(sheet, row: rowIndex, col: 2, value: taxLabel);
        _writeAmountCell(
          sheet,
          row: rowIndex,
          col: 3,
          value: _pickAmount(row.values),
        );
        if (_isGrandTaxTotalLabel(taxLabel)) {
          _applyFooterStyle(sheet, rowIndex: rowIndex);
        } else {
          _applyTaxRowStyle(sheet, rowIndex: rowIndex);
        }
        return;

      case 'total':
      case 'formula':
        _writeTextCell(sheet, row: rowIndex, col: 0, value: '');
        _writeTextCell(sheet, row: rowIndex, col: 1, value: '');
        _writeTextCell(
          sheet,
          row: rowIndex,
          col: 2,
          value: row.values['dien_giai']?.toString() ?? '',
        );
        _writeAmountCell(
          sheet,
          row: rowIndex,
          col: 3,
          value: _pickAmount(row.values),
        );
        if (_isGrandTaxTotalLabel(summaryLabel)) {
          _applyFooterStyle(sheet, rowIndex: rowIndex);
        } else {
          _applyTaxRowStyle(sheet, rowIndex: rowIndex);
        }
        return;
    }

    _writeTextCell(
      sheet,
      row: rowIndex,
      col: 0,
      value: _pick(row.values, 'so_hieu', _soHieuAliases)?.toString() ?? '',
    );
    _writeTextCell(
      sheet,
      row: rowIndex,
      col: 1,
      value: _fmtDate(_pick(row.values, 'ngay_thang', _dateAliases)),
    );
    _writeTextCell(
      sheet,
      row: rowIndex,
      col: 2,
      value: _pick(row.values, 'dien_giai', _descAliases)?.toString() ?? '',
    );
    _writeAmountCell(
      sheet,
      row: rowIndex,
      col: 3,
      value: _pickAmount(row.values),
    );
    _cell(sheet, rowIndex, 2).cellStyle.hAlign = xlsio.HAlignType.center;
    if (_isGrandTaxTotalLabel(summaryLabel)) {
      _applyFooterStyle(sheet, rowIndex: rowIndex);
    }
  }

  static xlsio.Worksheet _ensureSheet(xlsio.Workbook workbook) {
    if (workbook.worksheets.count > 0) {
      return workbook.worksheets[0];
    }
    return workbook.worksheets.addWithName('s2a');
  }

  static void _buildTemplateScaffold(xlsio.Worksheet sheet) {
    sheet.name = 's2a';

    sheet.getRangeByIndex(1, 1, 1, 3).merge();
    sheet.getRangeByIndex(3, 1, 3, 4).merge();
    sheet.getRangeByIndex(4, 1, 4, 4).merge();
    sheet.getRangeByIndex(5, 1, 5, 4).merge();
    sheet.getRangeByIndex(7, 1, 7, 2).merge();
    sheet.getRangeByIndex(7, 3, 8, 3).merge();
    sheet.getRangeByIndex(7, 4, 8, 4).merge();

    sheet.getRangeByIndex(1, 1).columnWidth = 20;
    sheet.getRangeByIndex(1, 2).columnWidth = 16;
    sheet.getRangeByIndex(1, 3).columnWidth = 62;
    sheet.getRangeByIndex(1, 4).columnWidth = 49.7;

    sheet.getRangeByIndex(1, 1).rowHeight = 98.25;

    _writeTextCell(
      sheet,
      row: 0,
      col: 0,
      value: 'HỘ, CÁ NHÂN KINH DOANH:\nMã số thuế:\nĐịa chỉ:',
    );
    _writeTextCell(
      sheet,
      row: 0,
      col: 3,
      value:
          'Mẫu số S2a-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)',
    );
    _writeTextCell(
      sheet,
      row: 2,
      col: 0,
      value: 'SỔ DOANH THU BÁN HÀNG HÓA, DỊCH VỤ',
    );
    _writeTextCell(sheet, row: 3, col: 0, value: 'Địa điểm kinh doanh:');
    _writeTextCell(sheet, row: 4, col: 0, value: 'Kỳ kê khai:');

    _writeTextCell(sheet, row: 6, col: 0, value: 'Chứng từ');
    _writeTextCell(sheet, row: 6, col: 2, value: 'Diễn giải');
    _writeTextCell(sheet, row: 6, col: 3, value: 'Số tiền');
    _writeTextCell(sheet, row: 7, col: 0, value: 'Số hiệu');
    _writeTextCell(sheet, row: 7, col: 1, value: 'Ngày, tháng');
    _writeTextCell(sheet, row: 8, col: 0, value: 'A');
    _writeTextCell(sheet, row: 8, col: 1, value: 'B');
    _writeTextCell(sheet, row: 8, col: 2, value: 'C');
    _writeTextCell(sheet, row: 8, col: 3, value: '1');

    _applyHeaderRowStyle(sheet, rowIndex: 6, fontSize: 10);
    _applyHeaderRowStyle(sheet, rowIndex: 7, fontSize: 10);
    _applyHeaderRowStyle(sheet, rowIndex: 8, fontSize: 10);

    final businessInfoStyle = sheet.getRangeByIndex(1, 1).cellStyle;
    businessInfoStyle.fontName = 'Times New Roman';
    businessInfoStyle.fontSize = 12;
    businessInfoStyle.bold = true;
    businessInfoStyle.wrapText = true;
    businessInfoStyle.vAlign = xlsio.VAlignType.center;
    businessInfoStyle.hAlign = xlsio.HAlignType.left;

    final titleStyle = sheet.getRangeByIndex(3, 1).cellStyle;
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

    final locationStyle = sheet.getRangeByIndex(4, 1).cellStyle;
    locationStyle.fontName = 'Times New Roman';
    locationStyle.fontSize = 12;
    locationStyle.hAlign = xlsio.HAlignType.center;

    final periodStyle = sheet.getRangeByIndex(5, 1).cellStyle;
    periodStyle.fontName = 'Times New Roman';
    periodStyle.fontSize = 12;
    periodStyle.hAlign = xlsio.HAlignType.center;
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
  }

  static void _writeSignatureBlock(
    xlsio.Worksheet sheet, {
    required int startRow,
  }) {
    _writeTextCell(
      sheet,
      row: startRow,
      col: 3,
      value: 'Ngày ... tháng ... năm ...',
    );
    _writeTextCell(
      sheet,
      row: startRow + 1,
      col: 3,
      value: 'NGƯỜI ĐẠI DIỆN HỘ KINH DOANH/',
    );
    _writeTextCell(
      sheet,
      row: startRow + 2,
      col: 3,
      value: 'CÁ NHÂN KINH DOANH',
    );
    _writeTextCell(
      sheet,
      row: startRow + 3,
      col: 3,
      value: '(Ký, ghi rõ họ tên và đóng dấu (nếu có))',
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
      range.cellStyle.hAlign = xlsio.HAlignType.right;
      return;
    }

    range.setNumber(numericValue);
    range.numberFormat = numericValue == numericValue.roundToDouble()
        ? '#,##0'
        : '#,##0.00';
    range.cellStyle.fontName = 'Times New Roman';
    range.cellStyle.fontSize = 12;
    range.cellStyle.hAlign = xlsio.HAlignType.right;
  }

  static void _applyHeaderRowStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
    required double fontSize,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final style = _cell(sheet, rowIndex, col).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = fontSize;
      style.hAlign = xlsio.HAlignType.center;
      style.vAlign = xlsio.VAlignType.center;
      style.bold = true;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
    }
  }

  static void _applyBaseRowStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final style = _cell(sheet, rowIndex, col).cellStyle;
      style.fontName = 'Times New Roman';
      style.fontSize = 12;
      style.vAlign = xlsio.VAlignType.center;
      style.hAlign = col == 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
      style.bold = false;
      style.italic = false;
    }
  }

  static void _applyIndustryHeaderStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final style = _cell(sheet, rowIndex, col).cellStyle;
      style.fontSize = 12;
      style.bold = false;
      style.italic = false;
      style.hAlign = col == 2 ? xlsio.HAlignType.left : xlsio.HAlignType.center;
    }
  }

  static void _applySubtotalStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final style = _cell(sheet, rowIndex, col).cellStyle;
      style.fontSize = 12;
      style.bold = false;
      style.italic = false;
      style.hAlign = xlsio.HAlignType.center;
    }
  }

  static void _applyTaxRowStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final style = _cell(sheet, rowIndex, col).cellStyle;
      style.fontSize = 12;
      style.bold = false;
      style.italic = false;
      style.hAlign = xlsio.HAlignType.center;
    }
  }

  static void _applyFooterStyle(
    xlsio.Worksheet sheet, {
    required int rowIndex,
  }) {
    for (var col = 0; col < _dataColumnCount; col++) {
      final style = _cell(sheet, rowIndex, col).cellStyle;
      style.fontSize = 12;
      style.bold = col >= 2;
      style.hAlign = col == 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
    }
  }

  static bool _isGrandTaxTotalLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return normalized.contains('tổng số thuế') ||
        normalized.contains('tong so thue');
  }

  static void _clearRow(xlsio.Worksheet sheet, {required int rowIndex}) {
    for (var col = 0; col < _dataColumnCount; col++) {
      _cell(sheet, rowIndex, col).setText('');
    }
  }

  static dynamic _pick(
    Map<String, dynamic> row,
    String primary,
    List<String> aliases,
  ) {
    final primaryValue = row[primary];
    if (primaryValue != null && primaryValue.toString().trim().isNotEmpty) {
      return primaryValue;
    }

    for (final alias in aliases) {
      final value = row[alias];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static dynamic _pickAmount(Map<String, dynamic> values) {
    return _pick(values, 'so_tien', _amountAliases);
  }

  static double? _toNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

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
    final patchedBytes = _applyS2aHeaderRichText(bytes);
    await file.writeAsBytes(patchedBytes, flush: true);
    return file;
  }

  static List<int> _applyS2aHeaderRichText(List<int> xlsxBytes) {
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
          'Mẫu số S2a-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)';
      final escapedPlainValue = _escapeXml(plainValue);
      const firstLine = 'Mẫu số S2a-HKD';
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

class _ExportRow {
  final String lineType;
  final Map<String, dynamic> values;
  final String? taxType;

  const _ExportRow({
    required this.lineType,
    required this.values,
    this.taxType,
  });
}
