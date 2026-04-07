import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Stats Cards - Hiển thị đơn hàng & doanh thu hôm nay
class StatsCards extends StatelessWidget {
  final String ordersTitle;
  final String revenueTitle;
  final String costTitle;
  final String debtTitle;
  final int todaysOrders;
  final String todaysRevenue;
  final String todaysCost;
  final String todaysDebt;
  final bool isRefreshing;

  const StatsCards({
    super.key,
    required this.ordersTitle,
    required this.revenueTitle,
    required this.costTitle,
    required this.debtTitle,
    this.todaysOrders = 24,
    this.todaysRevenue = '8.5M',
    this.todaysCost = '3.2M',
    this.todaysDebt = '1.1M',
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatCard(
          title: ordersTitle,
          value: todaysOrders.toString(),
          bgColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFFBBDEFB),
          isRefreshing: isRefreshing,
        ),
        SizedBox(height: AppSpacing.md),
        _StatCard(
          title: revenueTitle,
          value: todaysRevenue,
          bgColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFC8E6C9),
          valueColor: AppColors.success,
          isRefreshing: isRefreshing,
        ),
        SizedBox(height: AppSpacing.md),
        _StatCard(
          title: costTitle,
          value: todaysCost,
          bgColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFFFE0B2),
          valueColor: AppColors.warning,
          isRefreshing: isRefreshing,
        ),
        SizedBox(height: AppSpacing.md),
        _StatCard(
          title: debtTitle,
          value: todaysDebt,
          bgColor: const Color(0xFFFFEBEE),
          borderColor: const Color(0xFFFFCDD2),
          valueColor: AppColors.error,
          isRefreshing: isRefreshing,
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
  final bool isRefreshing;

  const _StatCard({
    required this.title,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    this.valueColor = AppColors.primary,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (isRefreshing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
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
