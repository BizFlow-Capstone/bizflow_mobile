import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../domain/models/accounting_book.dart';

class S2bExportService {
  const S2bExportService._();

  static const _startRow = 8;
  static const _columns = 4;

  static const _soHieuAliases = ['importCode', 'orderCode', 'bookCode', 'code', 'importId'];
  static const _dateAliases = ['receivedAt', 'createdAt', 'updatedAt', 'documentDate', 'date'];
  static const _descAliases = ['description', 'note', 'planName', 'businessLocationName', 'dien_giai'];
  static const _amountAliases = ['finalAmount', 'totalAmount', 'amount', 'planPrice', 'revenue', 'so_tien'];

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
      final sheet = _ensureSheet(workbook, 'S2b');
      _buildScaffold(sheet);
      _writeBusinessInfo(sheet, businessName: businessName, taxCode: taxCode, address: address);
      _writeLabel(sheet, row: 3, label: 'Dia diem kinh doanh', value: locationName);
      _writeLabel(sheet, row: 4, label: 'Ky ke khai', value: periodLabel);

      final rows = _buildRows(dataRows, sectionsData);
      final visible = rows.isEmpty ? 1 : rows.length;
      for (var i = 0; i < visible; i++) {
        final r = _startRow + i;
        _applyRowStyle(sheet, r);
        if (i >= rows.length) {
          _clearRow(sheet, r);
          continue;
        }
        final item = rows[i];
        _setText(sheet, r, 0, _pick(item, 'so_hieu', _soHieuAliases)?.toString() ?? '');
        _setText(sheet, r, 1, _fmtDate(_pick(item, 'ngay_thang', _dateAliases)));
        _setText(sheet, r, 2, _pick(item, 'dien_giai', _descAliases)?.toString() ?? '');
        _setAmount(sheet, r, 3, _pick(item, 'so_tien', _amountAliases));
      }

      return await _save(workbook, book.displayName);
    } catch (e, st) {
      // ignore: avoid_print
      print('S2bExportService export failed: $e\n$st');
      return null;
    } finally {
      workbook.dispose();
    }
  }

  static List<Map<String, dynamic>> _buildRows(
    List<Map<String, dynamic>> dataRows,
    BookSectionsResponse? sectionsData,
  ) {
    if (sectionsData == null || sectionsData.sections.isEmpty) return dataRows;
    final out = <Map<String, dynamic>>[];
    for (final section in sectionsData.sections) {
      for (final row in section.rows) {
        if (row.lineType == 'data') out.add(row.values);
      }
    }
    return out.isEmpty ? dataRows : out;
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
    sheet.getRangeByIndex(1, 1).columnWidth = 20;
    sheet.getRangeByIndex(1, 2).columnWidth = 14;
    sheet.getRangeByIndex(1, 3).columnWidth = 48;
    sheet.getRangeByIndex(1, 4).columnWidth = 18;
    _setText(sheet, 0, 0, 'HO, CA NHAN KINH DOANH:\nMa so thue:\nDia chi:');
    _setText(sheet, 3, 0, 'Dia diem kinh doanh:');
    _setText(sheet, 4, 0, 'Ky ke khai:');
    _setText(sheet, 6, 0, 'So hieu');
    _setText(sheet, 6, 1, 'Ngay thang');
    _setText(sheet, 6, 2, 'Dien giai');
    _setText(sheet, 6, 3, 'So tien');
    for (var c = 0; c < _columns; c++) {
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
      style.hAlign = c == 3 ? xlsio.HAlignType.right : xlsio.HAlignType.left;
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

  static Future<File?> _save(xlsio.Workbook workbook, String displayName) async {
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
    await file.writeAsBytes(workbook.saveAsStream(), flush: true);
    return file;
  }
}
