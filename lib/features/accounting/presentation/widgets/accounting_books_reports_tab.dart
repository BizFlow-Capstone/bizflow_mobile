import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../models/accounting_mock_models.dart';

class AccountingBooksReportsTab extends StatelessWidget {
  final List<BookItemModel> books;
  final List<TaxPaymentItemModel> taxPayments;
  final DateTime fromDate;
  final DateTime toDate;
  final String reportFormat;
  final ValueChanged<BookItemModel> onExportBook;
  final ValueChanged<TaxPaymentItemModel> onEditTaxPayment;
  final ValueChanged<DateTime> onFromDateChanged;
  final ValueChanged<DateTime> onToDateChanged;
  final ValueChanged<String> onReportFormatChanged;
  final VoidCallback onGenerateReport;

  const AccountingBooksReportsTab({
    super.key,
    required this.books,
    required this.taxPayments,
    required this.fromDate,
    required this.toDate,
    required this.reportFormat,
    required this.onExportBook,
    required this.onEditTaxPayment,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onReportFormatChanged,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _card(
          title: l10n.translate('accounting.accounting_books'),
          child: Column(
            children: books
                .map(
                  (book) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${book.code} - ${book.name}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(book.group, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => onExportBook(book),
                          child: Text(l10n.translate('accounting.export')),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _card(
          title: l10n.translate('accounting.tax_payments'),
          child: Column(
            children: taxPayments
                .map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${item.taxType} • ${CurrencyFormatter.formatVND(item.amount)}',
                    ),
                    subtitle: Text(item.reference),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => onEditTaxPayment(item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _card(
          title: l10n.translate('accounting.report_generator'),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context,
                      label: l10n.translate('accounting.from_date'),
                      date: fromDate,
                      onPicked: onFromDateChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _dateField(
                      context,
                      label: l10n.translate('accounting.to_date'),
                      date: toDate,
                      onPicked: onToDateChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: reportFormat,
                items: [
                  DropdownMenuItem(
                    value: 'pdf',
                    child: Text(l10n.translate('accounting.format_pdf')),
                  ),
                  DropdownMenuItem(
                    value: 'xlsx',
                    child: Text(l10n.translate('accounting.format_xlsx')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onReportFormatChanged(value);
                },
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.report_format'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGenerateReport,
                  child: Text(l10n.translate('accounting.generate_report')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text('${date.day}/${date.month}/${date.year}'),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
