import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/formatters.dart';

class AccountingPeriodTab extends StatelessWidget {
  final TextEditingController periodNameController;
  final TextEditingController openingCashController;
  final TextEditingController periodNoteController;
  final String periodType;
  final String accountingMethod;
  final ValueChanged<String> onPeriodTypeChanged;
  final ValueChanged<String> onAccountingMethodChanged;
  final VoidCallback onSave;

  const AccountingPeriodTab({
    super.key,
    required this.periodNameController,
    required this.openingCashController,
    required this.periodNoteController,
    required this.periodType,
    required this.accountingMethod,
    required this.onPeriodTypeChanged,
    required this.onAccountingMethodChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _infoCard(
            title: l10n.translate('accounting.rule_engine_suggestion'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('accounting.current_revenue_hint')),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.translate('accounting.suggested_group_value'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _infoCard(
            title: l10n.translate('accounting.period_settings'),
            child: Column(
              children: [
                TextField(
                  controller: periodNameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.period_name'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: periodType,
                  items: [
                    DropdownMenuItem(
                      value: 'quarterly',
                      child: Text(l10n.translate('accounting.period_quarterly')),
                    ),
                    DropdownMenuItem(
                      value: 'yearly',
                      child: Text(l10n.translate('accounting.period_yearly')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onPeriodTypeChanged(value);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.period_type'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: accountingMethod,
                  items: [
                    DropdownMenuItem(
                      value: 'method_1',
                      child: Text(l10n.translate('accounting.method_1')),
                    ),
                    DropdownMenuItem(
                      value: 'method_2',
                      child: Text(l10n.translate('accounting.method_2')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onAccountingMethodChanged(value);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.accounting_method'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: openingCashController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.opening_cash'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: periodNoteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.note'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSave,
                    child: Text(l10n.translate('common.save')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFEAEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
