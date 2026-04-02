import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';

class S2dExportService {
  const S2dExportService._();

  static const _startRow = 8;
  static const _columns = 11;

  static const _soHieuAliases = ['importCode', 'orderCode', 'bookCode', 'code', 'importId'];
  static const _dateAliases = ['ngay_thang', 'receivedAt', 'createdAt', 'updatedAt', 'documentDate', 'date'];
  static const _descAliases = ['description', 'note', 'planName', 'businessLocationName'];
  static const _dvtAliases = ['unit', 'unitName'];
  static const _donGiaAliases = ['unitPrice', 'price'];
  static const _slNhapAliases = ['importQuantity', 'quantityIn', 'slNhap'];
  static const _tienNhapAliases = ['importAmount', 'amountIn', 'tienNhap'];
  static const _slXuatAliases = ['exportQuantity', 'quantityOut', 'slXuat'];
  static const _tienXuatAliases = ['exportAmount', 'amountOut', 'tienXuat'];
  static const _slTonAliases = ['remainingQuantity', 'stockQuantity', 'slTon', 'tonCuoiKy'];
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
      _writeBusinessInfo(sheet, businessName: businessName, taxCode: taxCode, address: address);
      _writeLabel(sheet, row: 3, label: 'Dia diem kinh doanh', value: locationName);
      _writeLabel(sheet, row: 4, label: 'Ky ke khai', value: periodLabel);
      _writeLabel(sheet, row: 5, label: 'Ten vat lieu/san pham/hang hoa', value: categoryName);

      final visible = dataRows.isEmpty ? 1 : dataRows.length;
      for (var i = 0; i < visible; i++) {
        final r = _startRow + i;
        _applyRowStyle(sheet, r);
        if (i >= dataRows.length) {
          _clearRow(sheet, r);
          continue;
        }
        final row = dataRows[i];
        _setText(sheet, r, 0, _pick(row, 'so_hieu', _soHieuAliases)?.toString() ?? '');
        _setText(sheet, r, 1, _fmtDate(_pick(row, 'ngay', _dateAliases)));
        _setText(sheet, r, 2, _pick(row, 'dien_giai', _descAliases)?.toString() ?? '');
        _setText(sheet, r, 3, _pick(row, 'dvt', _dvtAliases)?.toString() ?? '');
        _setAmount(sheet, r, 4, _pick(row, 'don_gia', _donGiaAliases));
        _setAmount(sheet, r, 5, _pick(row, 'sl_nhap', _slNhapAliases));
        _setAmount(sheet, r, 6, _pick(row, 'tien_nhap', _tienNhapAliases));
        _setAmount(sheet, r, 7, _pick(row, 'sl_xuat', _slXuatAliases));
        _setAmount(sheet, r, 8, _pick(row, 'tien_xuat', _tienXuatAliases));
        _setAmount(sheet, r, 9, _pick(row, 'sl_ton', _slTonAliases));
        _setAmount(sheet, r, 10, _pick(row, 'tien_ton', _tienTonAliases));
      }

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
    final widths = [16.0, 12.0, 34.0, 10.0, 10.0, 10.0, 12.0, 10.0, 12.0, 10.0, 12.0];
    for (var i = 0; i < widths.length; i++) {
      sheet.getRangeByIndex(1, i + 1).columnWidth = widths[i];
    }
    _setText(sheet, 0, 0, 'HO, CA NHAN KINH DOANH:\nMa so thue:\nDia chi:');
    _setText(sheet, 3, 0, 'Dia diem kinh doanh:');
    _setText(sheet, 4, 0, 'Ky ke khai:');
    _setText(sheet, 5, 0, 'Ten vat lieu/san pham/hang hoa:');

    final headers = ['So hieu', 'Ngay', 'Dien giai', 'DVT', 'Don gia', 'SL nhap', 'Tien nhap', 'SL xuat', 'Tien xuat', 'SL ton', 'Tien ton'];
    for (var c = 0; c < headers.length; c++) {
      _setText(sheet, 6, c, headers[c]);
      final style = _cell(sheet, 6, c).cellStyle;
      style.bold = true;
      style.hAlign = xlsio.HAlignType.center;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
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
      'HO, CA NHAN KINH DOANH: ${businessName.trim()}\nMa so thue: ${taxCode.trim()}\nDia chi: ${address.trim()}',
    );
  }

  static void _writeLabel(
    xlsio.Worksheet sheet, {
    required int row,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) return;
    _setText(sheet, row, 0, '$label: ${value.trim()}');
  }

  static void _applyRowStyle(xlsio.Worksheet sheet, int row) {
    for (var c = 0; c < _columns; c++) {
      final style = _cell(sheet, row, c).cellStyle;
      style.borders.all.lineStyle = xlsio.LineStyle.thin;
      style.hAlign = c >= 4 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
      style.vAlign = xlsio.VAlignType.center;
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

  static void _setAmount(xlsio.Worksheet sheet, int row, int col, dynamic value) {
    final n = _toNum(value);
    if (n == null) {
      _setText(sheet, row, col, value?.toString() ?? '');
      return;
    }
    final cell = _cell(sheet, row, col);
    cell.setNumber(n.toDouble());
    cell.numberFormat = n == n.roundToDouble() ? '#,##0' : '#,##0.00';
  }

  static dynamic _pick(Map<String, dynamic> row, String primary, List<String> aliases) {
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
    final s = value.toString();
    if (s.isEmpty) return '';
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  static Future<File?> _save(xlsio.Workbook workbook, String displayName, String suffix) async {
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
    await file.writeAsBytes(workbook.saveAsStream(), flush: true);
    return file;
  }
}
