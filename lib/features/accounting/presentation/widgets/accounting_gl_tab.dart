import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../models/accounting_mock_models.dart';

class AccountingGlTab extends StatelessWidget {
  final String channelFilter;
  final List<GlEntryModel> entries;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onAddManual;

  const AccountingGlTab({
    super.key,
    required this.channelFilter,
    required this.entries,
    required this.onFilterChanged,
    required this.onAddManual,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _chip(context, 'all', l10n.translate('accounting.all')),
                    _chip(context, 'cash', l10n.translate('accounting.channel_cash')),
                    _chip(context, 'bank', l10n.translate('accounting.channel_bank')),
                    _chip(context, 'debt', l10n.translate('accounting.channel_debt')),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAddManual,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.secondary,
                tooltip: l10n.translate('accounting.add_manual_gl'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                      entry.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${entry.date.day}/${entry.date.month}/${entry.date.year} • ${entry.channel.toUpperCase()}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.translate('accounting.debit')}: ${CurrencyFormatter.formatVND(entry.debit)}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${l10n.translate('accounting.credit')}: ${CurrencyFormatter.formatVND(entry.credit)}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String key, String label) {
    final selected = channelFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onFilterChanged(key),
      selectedColor: AppColors.secondary.withValues(alpha: 0.15),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: selected ? AppColors.secondary : AppColors.textSecondary,
      ),
    );
  }
}
