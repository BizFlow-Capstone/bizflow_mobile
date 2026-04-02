import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/models/template_field_definition.dart';

class AccountingBookTableWidget extends StatelessWidget {
  final String templateCode;
  final List<Map<String, dynamic>> rows;
  final bool isLoading;

  const AccountingBookTableWidget({
    super.key,
    required this.templateCode,
    required this.rows,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final template = TemplateRegistry.getTemplate(templateCode);
    if (template == null) {
      return Center(child: Text('Unknown template: $templateCode'));
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      );
    }

    final displayColumns = template.displayColumns;
    final hasServerSummaryRows = _hasServerSummaryRows(rows, displayColumns);
    final visibleRows = rows
        .where((row) => _isVisibleRow(row, displayColumns))
        .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
          columns: [
            // Header columns
            ...displayColumns.map((field) {
              return DataColumn(
                numeric: field.fieldType == 'decimal',
                label: Text(
                  field.fieldLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
          rows: [
            // Data rows
            ...visibleRows.map((row) {
              final isEmphasizedRow = _isEmphasizedRow(row, displayColumns);
              final rowStyle = AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isEmphasizedRow ? FontWeight.bold : FontWeight.w500,
              );

              return DataRow(
                color: _buildRowColor(row, displayColumns),
                cells: [
                  ...displayColumns.map((field) {
                    final value = row[field.fieldCode];
                    final displayValue = _formatCellValue(
                      value,
                      field.fieldType,
                    );
                    return DataCell(Text(displayValue ?? '-', style: rowStyle));
                  }),
                ],
              );
            }),
            // Formula rows (summary/totals)
            ...(!hasServerSummaryRows
                    ? template.formulaFields
                    : const <TemplateFieldDefinition>[])
                .map((field) {
                  return DataRow(
                    color: WidgetStateProperty.all(Colors.grey[100]),
                    cells: [
                      ...displayColumns.map((displayField) {
                        if (displayField.fieldCode ==
                            displayColumns.first.fieldCode) {
                          // Show formula label on first column
                          return DataCell(
                            Text(
                              field.fieldLabel,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        // Calculate formula result if this is the numeric column
                        if (field.fieldCode == displayField.fieldCode) {
                          final result = _calculateFormula(
                            field.formulaExpression ?? '',
                            visibleRows,
                            displayColumns,
                          );
                          return DataCell(
                            Text(
                              result ?? '-',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return DataCell(
                          Text(
                            '-',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
          ],
        ),
      ),
    );
  }

  bool _hasServerSummaryRows(
    List<Map<String, dynamic>> rows,
    List<TemplateFieldDefinition> displayColumns,
  ) {
    if (rows.isEmpty || displayColumns.isEmpty) return false;

    for (final row in rows) {
      final lineType = (row['lineType'] ?? '').toString().toLowerCase();
      if (lineType == 'subtotal' ||
          lineType == 'total' ||
          lineType == 'formula' ||
          lineType == 'tax' ||
          lineType == 'tax_line' ||
          lineType == 'header' ||
          lineType == 'industry_header') {
        return true;
      }

      for (final column in displayColumns) {
        final cellValue = (row[column.fieldCode] ?? '')
            .toString()
            .toLowerCase();
        if (cellValue.contains('tổng') ||
            cellValue.contains('tong') ||
            cellValue.contains('thuế') ||
            cellValue.contains('thue') ||
            cellValue.contains('chênh lệch') ||
            cellValue.contains('chenh lech')) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isVisibleRow(
    Map<String, dynamic> row,
    List<TemplateFieldDefinition> displayColumns,
  ) {
    final lineType = (row['lineType'] ?? '').toString().toLowerCase();
    if (lineType == 'data_placeholder') {
      return false;
    }

    for (final column in displayColumns) {
      final value = row[column.fieldCode];
      if (value == null) {
        continue;
      }
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized != '-') {
        return true;
      }
    }
    return false;
  }

  bool _isEmphasizedRow(
    Map<String, dynamic> row,
    List<TemplateFieldDefinition> displayColumns,
  ) {
    final lineType = (row['lineType'] ?? '').toString().toLowerCase();
    if (lineType == 'subtotal' ||
        lineType == 'total' ||
        lineType == 'formula' ||
        lineType == 'tax' ||
        lineType == 'tax_line' ||
        lineType == 'header' ||
        lineType == 'industry_header') {
      return true;
    }

    for (final column in displayColumns) {
      final normalized = (row[column.fieldCode] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (normalized.contains('tổng') ||
          normalized.contains('tong') ||
          normalized.contains('thuế') ||
          normalized.contains('thue') ||
          normalized.contains('chênh lệch') ||
          normalized.contains('chenh lech') ||
          RegExp(r'^[ivx]+\.', caseSensitive: false).hasMatch(normalized)) {
        return true;
      }
    }

    return false;
  }

  WidgetStateProperty<Color?>? _buildRowColor(
    Map<String, dynamic> row,
    List<TemplateFieldDefinition> displayColumns,
  ) {
    final lineType = (row['lineType'] ?? '').toString().toLowerCase();
    if (lineType == 'header' || lineType == 'industry_header') {
      return WidgetStateProperty.all(Colors.amber[50]);
    }
    if (lineType == 'subtotal' ||
        lineType == 'total' ||
        lineType == 'formula') {
      return WidgetStateProperty.all(Colors.grey[100]);
    }
    if (lineType == 'tax' || lineType == 'tax_line') {
      return WidgetStateProperty.all(Colors.orange[50]);
    }

    for (final column in displayColumns) {
      final normalized = (row[column.fieldCode] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (normalized.contains('tổng') ||
          normalized.contains('tong') ||
          normalized.contains('chênh lệch') ||
          normalized.contains('chenh lech')) {
        return WidgetStateProperty.all(Colors.grey[100]);
      }
      if (normalized.contains('thuế') || normalized.contains('thue')) {
        return WidgetStateProperty.all(Colors.orange[50]);
      }
      if (RegExp(r'^[ivx]+\.', caseSensitive: false).hasMatch(normalized)) {
        return WidgetStateProperty.all(Colors.amber[50]);
      }
    }

    return null;
  }

  String? _formatCellValue(dynamic value, String fieldType) {
    if (value == null) return null;

    switch (fieldType) {
      case 'decimal':
        if (value is num) {
          return CurrencyFormatter.formatVND(value);
        }
        return value.toString();
      case 'date':
        if (value is String) {
          try {
            return DateTime.parse(value).toString().split(' ')[0];
          } catch (_) {
            return value;
          }
        }
        return value.toString();
      case 'auto_increment':
        return value.toString();
      case 'text':
        return value.toString();
      default:
        return value.toString();
    }
  }

  String? _calculateFormula(
    String expression,
    List<Map<String, dynamic>> rows,
    List<TemplateFieldDefinition> displayColumns,
  ) {
    // Simple formula calculation
    // In real app, would use a formula engine

    if (expression.startsWith('SUM(')) {
      // Extract field code from SUM(fieldCode)
      final match = RegExp(r'SUM\((\w+)\)').firstMatch(expression);
      if (match != null) {
        final fieldCode = match.group(1);
        final sum = rows.fold<num>(0, (prev, row) {
          final val = row[fieldCode];
          if (val is num) return prev + val;
          if (val is String) {
            try {
              return prev + num.parse(val);
            } catch (_) {
              return prev;
            }
          }
          return prev;
        });
        return CurrencyFormatter.formatVND(sum);
      }
    }

    if (expression.contains('*')) {
      // Simple multiplication (for tax calculations)
      // e.g., "cong_quy * VAT_RATE" - would need actual VAT_RATE
      // For now, return null to defer to backend calculation
      return null;
    }

    return null;
  }
}
