import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/location_entity.dart';

class LocationCard extends StatelessWidget {
  final LocationEntity location;
  final VoidCallback onTap;
  final Function(bool)? onToggleStatus; // nullable — hidden for employees
  final VoidCallback? onEdit;           // nullable — hidden for employees
  final VoidCallback? onDelete;         // nullable — hidden for employees
  final VoidCallback onAddManager;

  const LocationCard({
    super.key,
    required this.location,
    required this.onTap,
    required this.onAddManager,
    this.onToggleStatus,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: location.isActive ? onTap : null,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: location.isActive ? AppColors.white : AppColors.background,
          ),
          child: Stack(
            children: [
              // Main Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Name
                    Text(
                      location.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: location.isActive
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // Full Address (address, district, city)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: location.isActive
                              ? AppColors.textSecondary
                              : AppColors.textDisabled,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            location.fullAddress,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: location.isActive
                                  ? AppColors.textSecondary
                                  : AppColors.textDisabled,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),

                    // Phone Number
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: location.isActive
                              ? AppColors.textSecondary
                              : AppColors.textDisabled,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          location.phone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: location.isActive
                                ? AppColors.textSecondary
                                : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),

                    // Owner Info
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: location.isActive
                              ? AppColors.textSecondary
                              : AppColors.textDisabled,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            location.ownerName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: location.isActive
                                  ? AppColors.textSecondary
                                  : AppColors.textDisabled,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Top Right Actions — only shown for owners (callbacks non-null)
              if (onEdit != null || onDelete != null || onToggleStatus != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (onEdit != null) SizedBox(width: AppSpacing.sm),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      if (onDelete != null) SizedBox(width: AppSpacing.sm),
                      if (onToggleStatus != null)
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: location.isActive,
                            onChanged: onToggleStatus,
                            activeThumbColor: const Color(0xFF23C4C1),
                            activeTrackColor: AppColors.divider,
                            inactiveThumbColor: AppColors.textDisabled,
                            inactiveTrackColor: AppColors.divider,
                          ),
                        ),
                    ],
                  ),
                ),

              // Bottom: Add Manager Button (if no manager)
              if (location.ownerName.isEmpty)
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: GestureDetector(
                    onTap: onAddManager,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23C4C1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: const Color(0xFF23C4C1),
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'Thêm Nhân Viên',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFF23C4C1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
