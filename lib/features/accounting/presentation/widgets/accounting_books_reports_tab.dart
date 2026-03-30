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
        // Accounting Books - Primary Section
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('accounting.accounting_books'),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (books.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                l10n.translate('common.no_data'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...books.map((book) => _buildBookItem(context, book, l10n)),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Divider(),
        ),

        // Secondary Utilities
        _buildSectionHeader(
          l10n.translate('accounting.tax_payments'),
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTaxPayments(l10n),

        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(
          l10n.translate('accounting.report_generator'),
          Icons.assessment_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildReportGenerator(context, l10n),
        const SizedBox(height: 100), // Padding for FAB
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBookItem(
    BuildContext context,
    BookItemModel book,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(Icons.description_outlined, color: AppColors.secondary),
        ),
        title: Text(
          '${book.code} - ${book.name}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          book.group,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: ElevatedButton(
          onPressed: () => onExportBook(book),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
            foregroundColor: AppColors.secondary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          child: Text(
            l10n.translate('accounting.export'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTaxPayments(AppLocalizations l10n) {
    if (taxPayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Center(
          child: Text(
            l10n.translate('common.no_data'),
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    return Column(
      children: taxPayments
          .map(
            (item) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  '${item.taxType} • ${CurrencyFormatter.formatVND(item.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(item.reference),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => onEditTaxPayment(item),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildReportGenerator(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
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
            value: reportFormat,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerateReport,
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: Text(l10n.translate('accounting.generate_report')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

