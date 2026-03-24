import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../revenue/domain/entities/revenue_entity.dart';
import '../models/accounting_mock_models.dart';

class AccountingCostRevenueTab extends StatelessWidget {
  final List<RevenueEntity> revenues;
  final List<AccountingItemModel> costs;
  final VoidCallback onAddRevenue;
  final VoidCallback onAddCost;
  final ValueChanged<RevenueEntity> onEditRevenue;
  final ValueChanged<RevenueEntity> onTapRevenue;
  final ValueChanged<AccountingItemModel> onEditCost;

  const AccountingCostRevenueTab({
    super.key,
    required this.revenues,
    required this.costs,
    required this.onAddRevenue,
    required this.onAddCost,
    required this.onEditRevenue,
    required this.onTapRevenue,
    required this.onEditCost,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _card(
          title: l10n.translate('accounting.revenue_list'),
          onAdd: onAddRevenue,
          child: Column(
            children: revenues
                .map(
                  (item) => _itemTile(
                    context,
                    item: item,
                    isRevenue: true,
                    onTap: () => onTapRevenue(item),
                    onEdit: () => onEditRevenue(item),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _card(
          title: l10n.translate('accounting.cost_list'),
          onAdd: onAddCost,
          child: Column(
            children: costs
                .map(
                  (item) => _itemTile(
                    context,
                    item: item,
                    isRevenue: false,
                    onTap: null,
                    onEdit: () => onEditCost(item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _itemTile(
    BuildContext context, {
    required dynamic item,
    required bool isRevenue,
    VoidCallback? onTap,
    required VoidCallback onEdit,
  }) {
    String title = '';
    String subtitle = '';
    double amount = 0;

    if (item is RevenueEntity) {
      title = 'REV-${item.id}';
      subtitle = item.description;
      amount = item.amount;
    } else if (item is AccountingItemModel) {
      title = item.code;
      subtitle = item.description;
      amount = item.amount;
    }

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.formatVND(amount),
            style: AppTextStyles.labelSmall.copyWith(
              color: isRevenue ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    VoidCallback? onAdd,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onAdd != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: onAdd,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
