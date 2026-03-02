import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Stats Cards - Hiển thị đơn hàng & doanh thu hôm nay
class StatsCards extends StatelessWidget {
  final int todaysOrders;
  final String todaysRevenue;

  const StatsCards({
    super.key,
    this.todaysOrders = 24,
    this.todaysRevenue = '8.5M',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        // Orders Card
        Expanded(
          child: _StatCard(
            title: l10n.translate('home.todays_orders'),
            value: todaysOrders.toString(),
            bgColor: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFFBBDEFB),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        // Revenue Card
        Expanded(
          child: _StatCard(
            title: l10n.translate('home.todays_revenue'),
            value: todaysRevenue,
            bgColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFFC8E6C9),
            valueColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}

/// Individual Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color bgColor;
  final Color borderColor;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    this.valueColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.displaySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
