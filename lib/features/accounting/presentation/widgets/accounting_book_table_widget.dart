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
      return Center(
        child: Text('Unknown template: $templateCode'),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final displayColumns = template.displayColumns;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            // Header columns
            ...displayColumns.map((field) {
              return DataColumn(
                label: Text(
                  field.fieldLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
          rows: [
            // Data rows
            ...rows.map((row) {
              return DataRow(
                cells: [
                  ...displayColumns.map((field) {
                    final value = row[field.fieldCode];
                    final displayValue = _formatCellValue(
                      value,
                      field.fieldType,
                    );
                    return DataCell(
                      Text(
                        displayValue ?? '-',
                        style: AppTextStyles.bodySmall,
                      ),
                    );
                  }),
                ],
              );
            }),
            // Formula rows (summary/totals)
            ...template.formulaFields.map((field) {
              return DataRow(
                color: WidgetStateProperty.all(
                  Colors.grey[100],
                ),
                cells: [
                  ...displayColumns.map((displayField) {
                    if (displayField.fieldCode == displayColumns.first.fieldCode) {
                      // Show formula label on first column
                      return DataCell(
                        Text(
                          field.fieldLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    // Calculate formula result if this is the numeric column
                    if (field.fieldCode == displayField.fieldCode) {
                      final result = _calculateFormula(
                        field.formulaExpression ?? '',
                        rows,
                        displayColumns,
                      );
                      return DataCell(
                        Text(
                          result ?? '-',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const DataCell(Text('-'));
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String? _formatCellValue(
    dynamic value,
    String fieldType,
  ) {
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
