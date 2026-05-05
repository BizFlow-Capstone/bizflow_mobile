import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Management Cards - Quản lý Địa điểm & Nhân viên
class ManagementCards extends StatelessWidget {
  final int locationsCount;
  final int employeesCount;
  final bool showEmployeesCard;
  final VoidCallback? onProductsTab;
  final VoidCallback? onLocationsTab;
  final VoidCallback? onEmployeesTab;

  const ManagementCards({
    super.key,
    this.locationsCount = 0,
    this.employeesCount = 0,
    this.showEmployeesCard = true,
    this.onProductsTab,
    this.onLocationsTab,
    this.onEmployeesTab,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _ManagementCard(
          icon: Icons.inventory_2_outlined,
          iconColor: const Color(0xFF4CAF50),
          title: l10n.translate('home.manage_products'),
          subtitle: l10n.translate('home.products_active'),
          onTap: onProductsTab,
        ),
        SizedBox(height: AppSpacing.md),
        _ManagementCard(
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFF00BCD4),
          title: l10n.translate('home.manage_locations'),
          subtitle: l10n.translate(
            'home.locations_active',
            params: {'count': locationsCount.toString()},
          ),
          onTap: onLocationsTab,
        ),
        if (showEmployeesCard) ...[
          SizedBox(height: AppSpacing.md),
          _ManagementCard(
            icon: Icons.people_outlined,
            iconColor: const Color(0xFF7C3AED),
            title: l10n.translate('home.manage_employees'),
            subtitle: l10n.translate(
              'home.employees_count',
              params: {'count': employeesCount.toString()},
            ),
            onTap: onEmployeesTab,
          ),
        ],
      ],
    );
  }
}

/// Individual Management Card
class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ManagementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 28)),
            ),
            SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    ));
  }
}
