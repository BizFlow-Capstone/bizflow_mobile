import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../revenue/domain/entities/revenue_entity.dart';
import '../../../cost/domain/entities/cost_entity.dart';
import '../../../accounting/domain/utils/accounting_reference_display.dart';

enum AccountingCostRevenueMode { revenue, cost, both }

class AccountingCostRevenueTab extends StatelessWidget {
  final List<RevenueEntity> revenues;
  final List<CostEntity> costs;
  final AccountingCostRevenueMode mode;
  final String languageCode;
  final VoidCallback onAddRevenue;
  final VoidCallback onAddCost;
  final ValueChanged<RevenueEntity> onEditRevenue;
  final ValueChanged<RevenueEntity> onTapRevenue;
  final ValueChanged<RevenueEntity> onDeleteRevenue;
  final ValueChanged<CostEntity> onEditCost;
  final ValueChanged<CostEntity> onTapCost;
  final ValueChanged<CostEntity> onDeleteCost;

  const AccountingCostRevenueTab({
    super.key,
    required this.revenues,
    required this.costs,
    this.mode = AccountingCostRevenueMode.both,
    this.languageCode = 'vi',
    required this.onAddRevenue,
    required this.onAddCost,
    required this.onEditRevenue,
    required this.onTapRevenue,
    required this.onDeleteRevenue,
    required this.onEditCost,
    required this.onTapCost,
    required this.onDeleteCost,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showRevenue =
        mode == AccountingCostRevenueMode.both ||
        mode == AccountingCostRevenueMode.revenue;
    final showCost =
        mode == AccountingCostRevenueMode.both ||
        mode == AccountingCostRevenueMode.cost;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (showRevenue)
          _card(
            title: l10n.translate('accounting.revenue_list'),
            onAdd: onAddRevenue,
            child: revenues.isEmpty
                ? _buildEmptyState(
                    context,
                    l10n.translate('accounting.revenue_list'),
                  )
                : Column(
                    children: revenues
                        .map(
                          (item) => _itemTile(
                            context,
                            item: item,
                            isRevenue: true,
                            onTap: () => onTapRevenue(item),
                            onEdit: () => onEditRevenue(item),
                            onDelete: () => onDeleteRevenue(item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        if (showRevenue && showCost) const SizedBox(height: AppSpacing.md),
        if (showCost)
          _card(
            title: l10n.translate('accounting.cost_list'),
            onAdd: onAddCost,
            child: costs.isEmpty
                ? _buildEmptyState(
                    context,
                    l10n.translate('accounting.cost_list'),
                  )
                : Column(
                    children: costs
                        .map(
                          (item) => _itemTile(
                            context,
                            item: item,
                            isRevenue: false,
                            onTap: () => onTapCost(item),
                            onEdit: () => onEditCost(item),
                            onDelete: () => onDeleteCost(item),
                          ),
                        )
                        .toList(),
                  ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        '$title: 0',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _itemTile(
    BuildContext context, {
    required dynamic item,
    required bool isRevenue,
    VoidCallback? onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    String title = '';
    String subtitle = '';
    double amount = 0;
    bool canModify = false;
    final effectiveLanguageCode = languageCode;

    if (item is RevenueEntity) {
      title = AccountingReferenceDisplay.displayReference(
        referenceType: 'revenue',
        referenceId: item.id,
        languageCode: effectiveLanguageCode,
        fallback: 'REV-${item.id}',
      );
      subtitle = AccountingReferenceDisplay.displayDescriptionValue(
        description: item.description,
        referenceType: item.referenceType ?? 'revenue',
        referenceId: item.referenceId ?? item.id,
        referenceCode: item.referenceCode,
        languageCode: effectiveLanguageCode,
      );
      amount = item.amount;
      canModify = _isManualRevenue(item);
    } else if (item is CostEntity) {
      title = AccountingReferenceDisplay.displayReference(
        referenceType: 'cost',
        referenceId: item.id,
        languageCode: effectiveLanguageCode,
        fallback: 'COST-${item.id}',
      );
      subtitle = AccountingReferenceDisplay.displayDescriptionValue(
        description: item.description,
        referenceType: item.referenceType ?? 'cost',
        referenceId: item.referenceId ?? item.id,
        referenceCode: item.referenceCode,
        languageCode: effectiveLanguageCode,
      );
      amount = item.amount;
      canModify = _isManualCost(item);
    }

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.formatVND(amount),
            style: AppTextStyles.labelSmall.copyWith(
              color: isRevenue ? AppColors.success : AppColors.error,
            ),
          ),
          if (canModify) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ] else ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.lock_outline,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  bool _isManualRevenue(RevenueEntity item) {
    final type = item.type.trim().toLowerCase();
    final referenceType = (item.referenceType ?? '').trim().toLowerCase();
    return type == 'manual' || referenceType == 'manual';
  }

  bool _isManualCost(CostEntity item) {
    final type = item.type.trim().toLowerCase();
    final referenceType = (item.referenceType ?? '').trim().toLowerCase();
    if (referenceType == 'manual') {
      return true;
    }
    if (type == 'import') {
      return false;
    }

    // Import and other system-generated costs usually carry an external reference.
    if (item.referenceId != null &&
        item.referenceId! > 0 &&
        referenceType.isNotEmpty &&
        referenceType != 'cost') {
      return false;
    }

    return true;
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
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
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
