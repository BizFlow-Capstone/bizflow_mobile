import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/accounting_book.dart';

/// Widget hiển thị Sổ tài sản cố định mẫu S3a-HKD (TT152)
/// 8 cột: STT | Tên tài sản | Số chứng từ | Ngày ghi nhận |
///         Giá trị tăng | Giá trị giảm | Giá trị còn lại | Ghi chú
class S3aBookWidget extends StatelessWidget {
  final BookSectionsResponse sections;
  final List<Map<String, dynamic>> dataRows;

  const S3aBookWidget({
    super.key,
    required this.sections,
    this.dataRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildHeader(context), _buildTable(context)],
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
            'Mẫu số S3a-HKD',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SỔ TÀI SẢN CỐ ĐỊNH',
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
    var sttCounter = 0;

    for (final section in sections.sections) {
      for (final row in section.rows) {
        switch (row.lineType) {
          case 'data_placeholder':
            final filter = row.businessTypeId ?? section.businessTypeId;
            final matching = dataRows.where((r) {
              if (filter == null) return true;
              return r['businessTypeId']?.toString() == filter ||
                  r['section']?.toString() == filter;
            });
            for (final dataRow in matching) {
              sttCounter++;
              tableRows.add(_buildDataRow(
                SectionRowDto(lineType: 'data', values: dataRow),
                sttCounter,
              ));
            }
          case 'data':
            sttCounter++;
            tableRows.add(_buildDataRow(row, sttCounter));
          case 'subtotal':
          case 'total':
            tableRows.add(_buildSubtotalRow(row));
          default:
            break;
        }
      }
    }

    for (final row in sections.footerRows) {
      tableRows.add(_buildSubtotalRow(row));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
        columnSpacing: 16,
        columns: _buildColumns(),
        rows: tableRows,
      ),
    );
  }

  List<BookColumnDto> _effectiveColumns() {
    if (sections.columns.isNotEmpty) {
      return sections.columns;
    }
    return const [
      BookColumnDto(fieldCode: 'stt', label: 'STT', fieldType: 'number'),
      BookColumnDto(fieldCode: 'asset_name', label: 'Tên tài sản', fieldType: 'text'),
      BookColumnDto(fieldCode: 'voucher_no', label: 'Số CT', fieldType: 'text'),
      BookColumnDto(fieldCode: 'recorded_date', label: 'Ngày ghi nhận', fieldType: 'date'),
      BookColumnDto(fieldCode: 'increase_amount', label: 'Giá trị tăng', fieldType: 'money'),
      BookColumnDto(fieldCode: 'decrease_amount', label: 'Giá trị giảm', fieldType: 'money'),
      BookColumnDto(fieldCode: 'remaining_amount', label: 'Giá trị còn lại', fieldType: 'money'),
      BookColumnDto(fieldCode: 'note', label: 'Ghi chú', fieldType: 'text'),
    ];
  }

  List<DataColumn> _buildColumns() {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return _effectiveColumns().map((column) {
      return DataColumn(
        label: Text(column.label, style: style),
        numeric: _isNumericColumn(column),
      );
    }).toList();
  }

  DataRow _buildDataRow(SectionRowDto row, int stt) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
    );
    return DataRow(
      cells: _buildRowCells(row.values, style, stt: stt),
    );
  }

  DataRow _buildSubtotalRow(SectionRowDto row) {
    final v = row.values;
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey[100]),
      cells: _buildRowCells(v, style),
    );
  }

  List<DataCell> _buildRowCells(Map<String, dynamic> values, TextStyle style, {int? stt}) {
    return _effectiveColumns().map((column) {
      final value = _resolveCellValue(values, column.fieldCode, stt: stt);
      return DataCell(Text(_formatCellValue(value, column.fieldCode), style: style));
    }).toList();
  }

  bool _isNumericColumn(BookColumnDto column) {
    final code = column.fieldCode.trim().toLowerCase();
    final type = column.fieldType.trim().toLowerCase();
    final label = column.label.trim().toLowerCase();
    return type == 'number' ||
        type == 'money' ||
        code == 'stt' ||
        code.contains('amount') ||
        label.contains('giá trị');
  }

  dynamic _resolveCellValue(Map<String, dynamic> values, String fieldCode, {int? stt}) {
    if (values.containsKey(fieldCode)) return values[fieldCode];
    final code = fieldCode.trim().toLowerCase();

    if (code == 'stt' || code == 'index' || code == 'serial') {
      return stt;
    }

    if (code.contains('asset') || code.contains('tai_san') || code.contains('name')) {
      return _pick(values, const ['asset_name', 'assetName', 'name', 'title', 'tenTaiSan', 'dien_giai', 'description']);
    }

    if (code.contains('voucher') || code.contains('so_hieu') || code.contains('document')) {
      return _pick(values, const ['voucher_no', 'voucherNo', 'so_hieu', 'documentNumber', 'DocumentNumber', 'so_chung_tu', 'documentNo', 'DocumentNo']);
    }

    if (code.contains('date') || code.contains('ngay')) {
      return _pick(values, const ['recorded_date', 'recordedDate', 'date', 'ngay_ghi_nhan', 'receivedAt', 'createdAt']);
    }

    if (code.contains('increase') || code.contains('tang') || (code.contains('amount') && code.contains('in'))) {
      return _pick(values, const ['increase_amount', 'increaseAmount', 'amountIn', 'tang', 'gia_tri_tang', 'revenue']);
    }

    if (code.contains('decrease') || code.contains('giam') || (code.contains('amount') && code.contains('out'))) {
      return _pick(values, const ['decrease_amount', 'decreaseAmount', 'amountOut', 'giam', 'gia_tri_giam', 'cost']);
    }

    if (code.contains('remaining') || code.contains('con_lai') || code.contains('remain')) {
      return _pick(values, const ['remaining_amount', 'remainingAmount', 'conLai', 'gia_tri_con_lai', 'remainValue', 'finalAmount', 'totalAmount']);
    }

    if (code.contains('note') || code.contains('ghi_chu') || code.contains('remark') || code.contains('description')) {
      return _pick(values, const ['note', 'ghi_chu', 'description', 'remark']);
    }

    return values.entries
        .firstWhere((e) => e.key.trim().toLowerCase() == code, orElse: () => const MapEntry('', null))
        .value;
  }

  String _formatCellValue(dynamic value, String fieldCode) {
    final code = fieldCode.trim().toLowerCase();
    if (code.contains('date') || code.contains('ngay')) {
      return _fmtDate(value);
    }
    if (code == 'stt' || code == 'index' || code == 'serial') {
      return value?.toString() ?? '';
    }
    if (code.contains('amount') || code.contains('gia_tri') || code.contains('tang') || code.contains('giam') || code.contains('remain')) {
      return _fmtAmount(value);
    }
    return value?.toString() ?? '';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static dynamic _pick(Map<String, dynamic> v, List<String> aliases) {
    for (final key in aliases) {
      final val = v[key];
      if (val != null && val.toString().trim().isNotEmpty) return val;
    }
    return null;
  }

  static String _fmtDate(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return DateFormatter.formatDate(value);
    }
    if (value is String && value.isNotEmpty) {
      try {
        final date = DateFormatter.parseApiDateTime(value);
        if (date != null) {
          return DateFormatter.formatDate(date);
        }
        return value;
      } catch (_) {
        return value;
      }
    }
    return value.toString();
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
}
