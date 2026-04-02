import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
        columns: [
          DataColumn(
            label: Text(
              'STT',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Tên tài sản',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Số CT',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Ngày ghi nhận',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Giá trị tăng',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Giá trị giảm',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Giá trị còn lại',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Ghi chú',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        rows: tableRows,
      ),
    );
  }

  DataRow _buildDataRow(SectionRowDto row, int stt) {
    final v = row.values;
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontSize: 15,
    );
    return DataRow(
      cells: [
        DataCell(Text('$stt', style: style)),
        DataCell(Text(_str(v, const ['asset_name', 'assetName', 'name', 'title', 'tenTaiSan']), style: style)),
        DataCell(Text(_str(v, const ['voucher_no', 'voucherNo', 'code', 'so_hieu', 'importCode']), style: style)),
        DataCell(Text(_fmtDate(_pick(v, const ['recorded_date', 'recordedDate', 'date', 'ngay_ghi_nhan', 'receivedAt', 'createdAt'])), style: style)),
        DataCell(Text(_fmtAmount(_pick(v, const ['increase_amount', 'increaseAmount', 'amountIn', 'tang', 'gia_tri_tang', 'revenue'])), style: style)),
        DataCell(Text(_fmtAmount(_pick(v, const ['decrease_amount', 'decreaseAmount', 'amountOut', 'giam', 'gia_tri_giam', 'cost'])), style: style)),
        DataCell(Text(_fmtAmount(_pick(v, const ['remaining_amount', 'remainingAmount', 'conLai', 'gia_tri_con_lai', 'remainValue', 'finalAmount', 'totalAmount'])), style: style)),
        DataCell(Text(_str(v, const ['note', 'ghi_chu', 'description', 'remark']), style: style)),
      ],
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
      cells: [
        const DataCell(SizedBox.shrink()),
        DataCell(Text(
          _str(v, const ['asset_name', 'assetName', 'dien_giai', 'description', 'name']),
          style: style,
        )),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(Text(_fmtAmount(_pick(v, const ['increase_amount', 'increaseAmount', 'amountIn', 'tang', 'revenue'])), style: style)),
        DataCell(Text(_fmtAmount(_pick(v, const ['decrease_amount', 'decreaseAmount', 'amountOut', 'giam', 'cost'])), style: style)),
        DataCell(Text(_fmtAmount(_pick(v, const ['remaining_amount', 'remainingAmount', 'conLai', 'finalAmount', 'totalAmount'])), style: style)),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static dynamic _pick(Map<String, dynamic> v, List<String> aliases) {
    for (final key in aliases) {
      final val = v[key];
      if (val != null && val.toString().trim().isNotEmpty) return val;
    }
    return null;
  }

  static String _str(Map<String, dynamic> v, List<String> aliases) =>
      _pick(v, aliases)?.toString() ?? '';

  static String _fmtDate(dynamic value) {
    if (value == null) return '';
    if (value is String && value.isNotEmpty) {
      try {
        final date = DateTime.parse(value);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
