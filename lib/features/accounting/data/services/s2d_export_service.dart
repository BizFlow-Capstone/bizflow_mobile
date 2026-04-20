import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';
import '../../../../shared/utils/date_formatter.dart';

class S2dExportService {
  const S2dExportService._();

  static const _startRow = 8;
  static const _columns = 12;
  static const _fontName = 'Times New Roman';
  static const _headerFontSize = 12.0;
  static const _dataFontSize = 10.0;

  static const _soHieuAliases = [
    'importCode',
    'orderCode',
    'bookCode',
    'code',
    'importId',
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
  static const _descAliases = [
    'dien_giai',
    'description',
    'note',
    'planName',
    'businessLocationName',
  ];
  static const _ghiChuAliases = ['ghi_chu', 'ghiChu', 'note', 'Memo'];
  static const _dvtAliases = ['unit', 'unitName'];
  static const _donGiaAliases = ['unitPrice', 'price'];
  static const _slNhapAliases = ['importQuantity', 'quantityIn', 'slNhap'];
  static const _tienNhapAliases = ['importAmount', 'amountIn', 'tienNhap'];
  static const _slXuatAliases = ['exportQuantity', 'quantityOut', 'slXuat'];
  static const _tienXuatAliases = ['exportAmount', 'amountOut', 'tienXuat'];
  static const _slTonAliases = [
    'remainingQuantity',
    'stockQuantity',
    'slTon',
    'tonCuoiKy',
  ];
  static const _tienTonAliases = ['remainingAmount', 'stockAmount', 'tienTon'];

  static Future<File?> export({
    required AccountingBook book,
    required List<Map<String, dynamic>> dataRows,
    required String categoryName,
    BookSectionsResponse? sectionsData,
    String businessName = '',
    String taxCode = '',
    String address = '',
    String locationName = '',
    String periodLabel = '',
  }) async {
    final workbook = xlsio.Workbook();
    try {
      final sheet = _ensureSheet(workbook, 'S2d');
      _buildScaffold(sheet);
      _writeBusinessInfo(
        sheet,
        businessName: businessName,
        taxCode: taxCode,
        address: address,
      );
      // Row 4 (index 3): "Tên vật liệu, dụng cụ, sản phẩm, hàng hóa: [name]"
      _writeLabel(
        sheet,
        row: 3,
        label: 'Tên vật liệu, dụng cụ, sản phẩm, hàng hóa',
        value: categoryName,
      );
      // Row 5 (index 4): "Kỳ kê khai: [period]"
      _writeLabel(sheet, row: 4, label: 'Kỳ kê khai', value: periodLabel);
      final sortedRows = [...dataRows]..sort(_compareRows);
      final openingRow = sortedRows.isNotEmpty ? sortedRows.first : null;
      final closingRow = sortedRows.isNotEmpty ? sortedRows.last : null;
      final totalImportQty = _sum(sortedRows, 'sl_nhap', _slNhapAliases);
      final totalImportValue = _sum(sortedRows, 'tien_nhap', _tienNhapAliases);
      final totalExportQty = _sum(sortedRows, 'sl_xuat', _slXuatAliases);
      final totalExportValue = _sum(sortedRows, 'tien_xuat', _tienXuatAliases);

      var r = _startRow;
      _writeSummaryRow(
        sheet,
        r++,
        label: 'Số dư đầu kỳ',
        unit:
            _pick(openingRow ?? const {}, 'dvt', _dvtAliases)?.toString() ?? '',
        unitPrice: _pick(openingRow ?? const {}, 'don_gia', _donGiaAliases),
        balanceQty:
            _pick(openingRow ?? const {}, 'sl_ton', _slTonAliases) ??
            _pick(openingRow ?? const {}, 'sl_nhap', _slNhapAliases),
        balanceValue:
            _pick(openingRow ?? const {}, 'tien_ton', _tienTonAliases) ??
            _pick(openingRow ?? const {}, 'tien_nhap', _tienNhapAliases),
      );

      for (final row in sortedRows) {
        _writeDataRow(sheet, r++, row);
      }

      _writeSummaryRow(
        sheet,
        r++,
        label: 'Cộng phát sinh trong kỳ',
        importQty: totalImportQty,
        importValue: totalImportValue,
        exportQty: totalExportQty,
        exportValue: totalExportValue,
      );
      _writeSummaryRow(
        sheet,
        r++,
        label: 'Số dư cuối kỳ',
        unit:
            _pick(closingRow ?? const {}, 'dvt', _dvtAliases)?.toString() ?? '',
        unitPrice: _pick(closingRow ?? const {}, 'don_gia', _donGiaAliases),
        balanceQty: _pick(closingRow ?? const {}, 'sl_ton', _slTonAliases),
        balanceValue: _pick(
          closingRow ?? const {},
          'tien_ton',
          _tienTonAliases,
        ),
      );

      _writeSignatureBlock(sheet, r + 1);

      return await _save(workbook, book.displayName, categoryName);
    } catch (e, st) {
      // ignore: avoid_print
      print('S2dExportService export failed: $e\n$st');
      return null;
    } finally {
      workbook.dispose();
    }
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
    final widths = [
      12.0,
      13.0,
      38.0,
      12.0,
      12.0,
      12.0,
      12.0,
      12.0,
      12.0,
      12.0,
      12.0,
      12.0,
    ];
    for (var i = 0; i < widths.length; i++) {
      sheet.getRangeByIndex(1, i + 1).columnWidth = widths[i];
    }
    _setText(sheet, 0, 0, 'HỘ, CÁ NHÂN KINH DOANH:\nMã số thuế:\nĐịa chỉ:');
    _setText(
      sheet,
      0,
      8,
      'Mẫu số S2d-HKD\n(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)',
    );
    _setText(sheet, 2, 0, 'SỔ CHI TIẾT VẬT LIỆU, DỤNG CỤ, SẢN PHẨM, HÀNG HÓA');
    _setText(sheet, 3, 0, 'Tên vật liệu, dụng cụ, sản phẩm, hàng hóa:');
    _setText(sheet, 4, 0, 'Kỳ kê khai:');

    _setText(sheet, 5, 0, 'Chứng từ');
    _setText(sheet, 5, 2, 'Diễn giải');
    _setText(sheet, 5, 3, 'Đơn vị tính');
    _setText(sheet, 5, 4, 'Đơn giá');
    _setText(sheet, 5, 5, 'Nhập');
    _setText(sheet, 5, 7, 'Xuất');
    _setText(sheet, 5, 9, 'Tồn');
    _setText(sheet, 5, 11, 'Ghi chú');

    _setText(sheet, 6, 0, 'Số hiệu');
    _setText(sheet, 6, 1, 'Ngày, tháng');
    _setText(sheet, 6, 5, 'Số lượng');
    _setText(sheet, 6, 6, 'Thành tiền');
    _setText(sheet, 6, 7, 'Số lượng');
    _setText(sheet, 6, 8, 'Thành tiền');
    _setText(sheet, 6, 9, 'Số lượng');
    _setText(sheet, 6, 10, 'Thành tiền');

    const markers = [
      'A',
      'B',
      'C',
      'D',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
    ];
    for (var c = 0; c < markers.length; c++) {
      _setText(sheet, 7, c, markers[c]);
    }

    sheet.getRangeByIndex(1, 1, 1, 3).merge(); // A1:C1 — business info
    sheet.getRangeByIndex(1, 1).rowHeight = 95.0; // ~127 px
    sheet.getRangeByIndex(1, 9, 1, 12).merge();
    sheet.getRangeByIndex(3, 1, 3, 12).merge();
    sheet.getRangeByIndex(4, 1, 4, 12).merge();
    sheet.getRangeByIndex(5, 1, 5, 12).merge();
    sheet.getRangeByIndex(6, 1, 6, 2).merge();
    sheet.getRangeByIndex(6, 3, 7, 3).merge();
    sheet.getRangeByIndex(6, 4, 7, 4).merge();
    sheet.getRangeByIndex(6, 5, 7, 5).merge();
    sheet.getRangeByIndex(6, 6, 6, 7).merge();
    sheet.getRangeByIndex(6, 8, 6, 9).merge();
    sheet.getRangeByIndex(6, 10, 6, 11).merge();
    sheet.getRangeByIndex(6, 12, 7, 12).merge();

    _styleHeaderCell(sheet, 0, 0, bold: true, center: true);
    _styleHeaderCell(sheet, 0, 8, bold: true, center: true);
    _styleHeaderCell(sheet, 2, 0, bold: true, center: true);
    _styleHeaderCell(sheet, 3, 0, center: true);
    _styleHeaderCell(sheet, 4, 0, center: true);
    for (var c = 0; c < _columns; c++) {
      _styleTableHeaderCell(sheet, 5, c);
      _styleTableHeaderCell(sheet, 6, c);
      _styleTableHeaderCell(sheet, 7, c, bold: false, fontSize: 10);
    }
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
    _styleHeaderCell(sheet, 0, 0, bold: true);
  }

  static void _writeLabel(
    xlsio.Worksheet sheet, {
    required int row,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) return;
    _setText(sheet, row, 0, '$label: ${value.trim()}');
    _styleHeaderCell(sheet, row, 0, center: true);
  }

  static void _applyRowStyle(xlsio.Worksheet sheet, int row) {
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.fontName = _fontName;
      style.fontSize = _dataFontSize;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
      style.hAlign = c >= 4 && c <= 10
          ? xlsio.HAlignType.right
          : xlsio.HAlignType.left;
      style.vAlign = xlsio.VAlignType.center;
    }
  }

  static void _styleTableHeaderCell(
    xlsio.Worksheet sheet,
    int row,
    int col, {
    bool bold = true,
    double fontSize = _headerFontSize,
  }) {
    final style = _cell(sheet, row, col).cellStyle;
    style.fontName = _fontName;
    style.fontSize = fontSize;
    style.bold = bold;
    style.hAlign = xlsio.HAlignType.center;
    style.vAlign = xlsio.VAlignType.center;
    style.borders.all.lineStyle = xlsio.LineStyle.thin;
  }

  static void _styleHeaderCell(
    xlsio.Worksheet sheet,
    int row,
    int col, {
    bool bold = false,
    bool center = false,
  }) {
    final style = _cell(sheet, row, col).cellStyle;
    style.fontName = _fontName;
    style.fontSize = _headerFontSize;
    style.bold = bold;
    style.vAlign = xlsio.VAlignType.center;
    style.wrapText = true;
    if (center) {
      style.hAlign = xlsio.HAlignType.center;
    }
  }

  static void _writeSignatureBlock(xlsio.Worksheet sheet, int startRow) {
    _setText(sheet, startRow, 8, 'Ngày ... tháng ... năm ...');
    _setText(sheet, startRow + 1, 8, 'NGƯỜI ĐẠI DIỆN HỘ KINH DOANH/');
    _setText(sheet, startRow + 2, 8, 'CÁ NHÂN KINH DOANH');
    _setText(sheet, startRow + 3, 8, '(Ký, họ tên, đóng dấu)');

    sheet.getRangeByIndex(startRow + 1, 9, startRow + 1, 12).merge();
    sheet.getRangeByIndex(startRow + 2, 9, startRow + 2, 12).merge();
    sheet.getRangeByIndex(startRow + 3, 9, startRow + 3, 12).merge();
    sheet.getRangeByIndex(startRow + 4, 9, startRow + 4, 12).merge();

    for (var r = startRow; r <= startRow + 3; r++) {
      _styleHeaderCell(
        sheet,
        r,
        8,
        bold: r == startRow + 1 || r == startRow + 2,
        center: true,
      );
    }
  }

  static void _writeDataRow(
    xlsio.Worksheet sheet,
    int rowIndex,
    Map<String, dynamic> row,
  ) {
    _applyRowStyle(sheet, rowIndex);
    _setText(
      sheet,
      rowIndex,
      0,
      _pick(row, 'so_hieu', _soHieuAliases)?.toString() ?? '',
    );
    _setText(sheet, rowIndex, 1, _fmtDate(_pick(row, 'ngay', _dateAliases)));
    _setText(
      sheet,
      rowIndex,
      2,
      _pick(row, 'dien_giai', _descAliases)?.toString() ?? '',
    );
    _setText(
      sheet,
      rowIndex,
      3,
      _pick(row, 'dvt', _dvtAliases)?.toString() ?? '',
    );
    _setAmount(sheet, rowIndex, 4, _pick(row, 'don_gia', _donGiaAliases));
    _setAmount(sheet, rowIndex, 5, _pick(row, 'sl_nhap', _slNhapAliases));
    _setAmount(sheet, rowIndex, 6, _pick(row, 'tien_nhap', _tienNhapAliases));
    _setAmount(sheet, rowIndex, 7, _pick(row, 'sl_xuat', _slXuatAliases));
    _setAmount(sheet, rowIndex, 8, _pick(row, 'tien_xuat', _tienXuatAliases));
    _setAmount(sheet, rowIndex, 9, _pick(row, 'sl_ton', _slTonAliases));
    _setAmount(sheet, rowIndex, 10, _pick(row, 'tien_ton', _tienTonAliases));
    _setText(
      sheet,
      rowIndex,
      11,
      _pick(row, 'ghi_chu', _ghiChuAliases)?.toString() ?? '',
    );
  }

  static void _writeSummaryRow(
    xlsio.Worksheet sheet,
    int rowIndex, {
    required String label,
    String unit = '',
    dynamic unitPrice,
    dynamic importQty,
    dynamic importValue,
    dynamic exportQty,
    dynamic exportValue,
    dynamic balanceQty,
    dynamic balanceValue,
  }) {
    _applyRowStyle(sheet, rowIndex);
    final style = _cell(sheet, rowIndex, 2).cellStyle;
    style.bold = true;
    _setText(sheet, rowIndex, 2, label);
    _setText(sheet, rowIndex, 3, unit);
    _setAmount(sheet, rowIndex, 4, unitPrice);
    _setAmount(sheet, rowIndex, 5, importQty);
    _setAmount(sheet, rowIndex, 6, importValue);
    _setAmount(sheet, rowIndex, 7, exportQty);
    _setAmount(sheet, rowIndex, 8, exportValue);
    _setAmount(sheet, rowIndex, 9, balanceQty);
    _setAmount(sheet, rowIndex, 10, balanceValue);
  }

  static int _compareRows(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aDate = _parseDate(_pick(a, 'ngay', _dateAliases));
    final bDate = _parseDate(_pick(b, 'ngay', _dateAliases));
    final dateCompare = (aDate ?? DateTime(1900)).compareTo(
      bDate ?? DateTime(1900),
    );
    if (dateCompare != 0) return dateCompare;

    final aSoHieu = int.tryParse(
      _pick(a, 'so_hieu', _soHieuAliases)?.toString() ?? '',
    );
    final bSoHieu = int.tryParse(
      _pick(b, 'so_hieu', _soHieuAliases)?.toString() ?? '',
    );
    return (aSoHieu ?? 0).compareTo(bSoHieu ?? 0);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static num _sum(
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

  static xlsio.Range _cell(xlsio.Worksheet sheet, int row, int col) {
    return sheet.getRangeByIndex(row + 1, col + 1);
  }

  static void _setText(xlsio.Worksheet sheet, int row, int col, String text) {
    _cell(sheet, row, col).setText(text);
  }

  static void _setAmount(
    xlsio.Worksheet sheet,
    int row,
    int col,
    dynamic value,
  ) {
    final n = _toNum(value);
    if (n == null) {
      _setText(sheet, row, col, value?.toString() ?? '');
      return;
    }
    final cell = _cell(sheet, row, col);
    cell.setNumber(n.toDouble());
    cell.numberFormat = n == n.roundToDouble() ? '#,##0' : '#,##0.00';
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

  static String _fmtDate(dynamic value) {
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

  static Future<File?> _save(
    xlsio.Workbook workbook,
    String displayName,
    String suffix,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = displayName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final safeSuffix = suffix
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    var file = File('${dir.path}/$safe - $safeSuffix.xlsx');
    var counter = 1;
    while (await file.exists()) {
      file = File('${dir.path}/$safe - $safeSuffix ($counter).xlsx');
      counter++;
    }
    final bytes = workbook.saveAsStream();
    final patchedBytes = _applyS2dHeaderRichText(bytes);
    await file.writeAsBytes(patchedBytes, flush: true);
    return file;
  }

  /// Post-process the XLSX bytes to apply rich text to the Mẫu số cell:
  /// "Mẫu số S2d-HKD" in bold, followed by the Thông tư line in normal weight.
  static List<int> _applyS2dHeaderRichText(List<int> xlsxBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);
      final idx = archive.files.indexWhere(
        (f) => f.name == 'xl/sharedStrings.xml',
      );
      if (idx < 0) return xlsxBytes;

      final file = archive.files[idx];
      final contentBytes = _toBytes(file.content);
      if (contentBytes == null || contentBytes.isEmpty) return xlsxBytes;

      var xml = utf8.decode(contentBytes, allowMalformed: true);

      const firstLine = 'Mẫu số S2d-HKD';
      const secondLine =
          '(Kèm theo Thông tư số 152/2025/TT-BTC ngày 31 tháng 12 năm 2025 của Bộ trưởng Bộ Tài chính)';
      const plainValue = '$firstLine\n$secondLine';

      final richSi =
          '<si>'
          '<r>'
          '<rPr><b/><sz val="12"/><rFont val="Times New Roman"/>'
          '<family val="2"/><charset val="0"/></rPr>'
          '<t>${_escapeXml(firstLine)}</t>'
          '</r>'
          '<r>'
          '<rPr><sz val="10"/><rFont val="Times New Roman"/>'
          '<family val="2"/><charset val="0"/></rPr>'
          '<t xml:space="preserve">\n${_escapeXml(secondLine)}</t>'
          '</r>'
          '</si>';

      final plain1 = '<si><t>${_escapeXml(plainValue)}</t></si>';
      final plain2 =
          '<si><t xml:space="preserve">${_escapeXml(plainValue)}</t></si>';

      var replaced = false;
      if (xml.contains(plain1)) {
        xml = xml.replaceFirst(plain1, richSi);
        replaced = true;
      } else if (xml.contains(plain2)) {
        xml = xml.replaceFirst(plain2, richSi);
        replaced = true;
      }

      if (!replaced) return xlsxBytes;

      final updatedBytes = utf8.encode(xml);
      final updatedFile = ArchiveFile(
        file.name,
        updatedBytes.length,
        updatedBytes,
      );

      final updated = Archive();
      for (var i = 0; i < archive.files.length; i++) {
        updated.addFile(i == idx ? updatedFile : archive.files[i]);
      }

      final encoded = ZipEncoder().encode(updated);
      return encoded ?? xlsxBytes;
    } catch (_) {
      return xlsxBytes;
    }
  }

  static List<int>? _toBytes(dynamic content) {
    if (content is List<int>) return content;
    if (content is String) return utf8.encode(content);
    try {
      final asUint8 = (content as dynamic).toUint8List();
      if (asUint8 is List<int>) return asUint8;
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
