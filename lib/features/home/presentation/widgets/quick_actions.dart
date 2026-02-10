import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Quick Actions - 4 nút action nhanh
class QuickActions extends StatelessWidget {
  final VoidCallback? onCreateOrder;
  final VoidCallback? onOrders;
  final VoidCallback? onDebt;
  final VoidCallback? onReport;

  const QuickActions({
    super.key,
    this.onCreateOrder,
    this.onOrders,
    this.onDebt,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionButton(
          icon: Icons.add_circle_outline,
          label: l10n.translate('home.create_order'),
          onTap: onCreateOrder,
        ),
        _QuickActionButton(
          icon: Icons.shopping_cart_outlined,
          label: l10n.translate('home.orders'),
          onTap: onOrders,
        ),
        _QuickActionButton(
          icon: Icons.credit_card_outlined,
          label: l10n.translate('home.debt'),
          onTap: onDebt,
        ),
        _QuickActionButton(
          icon: Icons.bar_chart_outlined,
          label: l10n.translate('home.reports'),
          onTap: onReport,
        ),
      ],
    );
  }
}

/// Individual Quick Action Button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
