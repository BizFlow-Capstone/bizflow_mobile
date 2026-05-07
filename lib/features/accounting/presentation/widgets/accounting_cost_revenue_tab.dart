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

class AccountingCostRevenueTab extends StatefulWidget {
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
  final bool Function(RevenueEntity) canModifyRevenue;
  final bool Function(CostEntity) canModifyCost;
  // Pagination callbacks/state (optional)
  final bool hasReachedMaxRevenue;
  final bool hasReachedMaxCost;
  final bool isLoadingMoreRevenue;
  final bool isLoadingMoreCost;
  final VoidCallback? onLoadMoreRevenue;
  final VoidCallback? onLoadMoreCost;
  final Future<void> Function()? onRefresh;

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
    required this.canModifyRevenue,
    required this.canModifyCost,
    this.hasReachedMaxRevenue = true,
    this.hasReachedMaxCost = true,
    this.isLoadingMoreRevenue = false,
    this.isLoadingMoreCost = false,
    this.onLoadMoreRevenue,
    this.onLoadMoreCost,
    this.onRefresh,
  });

  @override
  State<AccountingCostRevenueTab> createState() =>
      _AccountingCostRevenueTabState();
}

class _AccountingCostRevenueTabState extends State<AccountingCostRevenueTab> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current < (maxScroll * 0.9)) return;

    final showRevenue =
        widget.mode == AccountingCostRevenueMode.both ||
        widget.mode == AccountingCostRevenueMode.revenue;
    final showCost =
        widget.mode == AccountingCostRevenueMode.both ||
        widget.mode == AccountingCostRevenueMode.cost;

    // Try to load cost first (cost section is rendered after revenue).
    if (showCost &&
        widget.onLoadMoreCost != null &&
        !widget.hasReachedMaxCost &&
        !widget.isLoadingMoreCost) {
      widget.onLoadMoreCost!();
      return;
    }

    if (showRevenue &&
        widget.onLoadMoreRevenue != null &&
        !widget.hasReachedMaxRevenue &&
        !widget.isLoadingMoreRevenue) {
      widget.onLoadMoreRevenue!();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showRevenue =
        widget.mode == AccountingCostRevenueMode.both ||
        widget.mode == AccountingCostRevenueMode.revenue;
    final showCost =
        widget.mode == AccountingCostRevenueMode.both ||
        widget.mode == AccountingCostRevenueMode.cost;

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (showRevenue)
            _card(
              title: l10n.translate('accounting.revenue_list'),
              onAdd: widget.onAddRevenue,
              child: widget.revenues.isEmpty
                  ? _buildEmptyState(
                      context,
                      l10n.translate('accounting.revenue_list'),
                    )
                  : Column(
                      children: [
                        ...widget.revenues.map(
                          (item) => _itemTile(
                            context,
                            item: item,
                            isRevenue: true,
                            onTap: () => widget.onTapRevenue(item),
                            onEdit: () => widget.onEditRevenue(item),
                            onDelete: () => widget.onDeleteRevenue(item),
                            isModifiable: widget.canModifyRevenue(item),
                          ),
                        ),
                        if (widget.isLoadingMoreRevenue)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
          if (showRevenue && showCost) const SizedBox(height: AppSpacing.md),
          if (showCost)
            _card(
              title: l10n.translate('accounting.cost_list'),
              onAdd: widget.onAddCost,
              child: widget.costs.isEmpty
                  ? _buildEmptyState(
                      context,
                      l10n.translate('accounting.cost_list'),
                    )
                  : Column(
                      children: [
                        ...widget.costs.map(
                          (item) => _itemTile(
                            context,
                            item: item,
                            isRevenue: false,
                            onTap: () => widget.onTapCost(item),
                            onEdit: () => widget.onEditCost(item),
                            onDelete: () => widget.onDeleteCost(item),
                            isModifiable: widget.canModifyCost(item),
                          ),
                        ),
                        if (widget.isLoadingMoreCost)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
        ],
      ),
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
    required bool isModifiable,
    VoidCallback? onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    String title = '';
    String subtitle = '';
    double amount = 0;
    bool isReplaced = false;
    String? statusLabel;
    final effectiveLanguageCode = widget.languageCode;

    if (item is RevenueEntity) {
      final revenueCode = (item.revenueCode ?? '').trim();
      final referenceCode = (item.referenceCode ?? '').trim();

      // Build title: prioritize explicit codes only.
      if (revenueCode.isNotEmpty) {
        title = revenueCode;
      } else if (referenceCode.isNotEmpty) {
        title = referenceCode;
      } else {
        title = '-';
      }

      subtitle = AccountingReferenceDisplay.displayDescriptionValue(
        description: item.description,
        referenceType: item.referenceType ?? 'revenue',
        referenceId: item.referenceId ?? item.id,
        referenceCode: item.referenceCode ?? item.revenueCode,
        languageCode: effectiveLanguageCode,
      );
      amount = item.amount;
      isReplaced =
          (item.statusCode ?? '').trim().toLowerCase() == 'replaced' ||
          (item.statusCode ?? '').trim().toLowerCase() == 'cancelled';
      statusLabel = item.statusLabel;
    } else if (item is CostEntity) {
      final costCode = (item.costCode ?? '').trim();
      final referenceCode = (item.referenceCode ?? '').trim();

      // Build title: prioritize explicit codes only.
      if (costCode.isNotEmpty) {
        title = costCode;
      } else if (referenceCode.isNotEmpty) {
        title = referenceCode;
      } else {
        title = '-';
      }

      subtitle = AccountingReferenceDisplay.displayDescriptionValue(
        description: item.description,
        referenceType: item.referenceType ?? 'cost',
        referenceId: item.referenceId ?? item.id,
        referenceCode: item.referenceCode ?? item.costCode,
        languageCode: effectiveLanguageCode,
      );
      amount = item.amount;
      isReplaced =
          (item.statusCode ?? '').trim().toLowerCase() == 'replaced' ||
          (item.statusCode ?? '').trim().toLowerCase() == 'cancelled';
      statusLabel = item.statusLabel;
    }

    final textDecoration = isReplaced
        ? TextDecoration.lineThrough
        : TextDecoration.none;
    final editable = isModifiable && !isReplaced;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                decoration: textDecoration,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(decoration: textDecoration),
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
              decoration: textDecoration,
            ),
          ),
          if (editable) ...[
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
