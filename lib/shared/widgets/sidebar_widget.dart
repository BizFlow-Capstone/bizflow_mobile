import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Mô hình dữ liệu cho Location trong Sidebar
class LocationItem {
  final String id;
  final String name;
  final String? logoUrl;
  final bool isActive;

  LocationItem({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isActive = true,
  });
}

/// Sidebar Component
/// Chứa: Logo + Tên địa điểm kinh doanh, Nút thêm địa điểm
/// Các action: Đăng xuất, Hướng dẫn, Gói đang sử dụng, Cài đặt tài khoản
class SidebarWidget extends StatefulWidget {
  final List<LocationItem> locations;
  final LocationItem? selectedLocation;
  final VoidCallback onAddLocation;
  final VoidCallback onLogout;
  final VoidCallback onGuide;
  final VoidCallback onAccountSettings;
  final VoidCallback? onPackage;
  final Function(LocationItem)? onLocationSelected;
  final String? userLogo;

  const SidebarWidget({
    super.key,
    required this.locations,
    required this.onAddLocation,
    required this.onLogout,
    required this.onGuide,
    required this.onAccountSettings,
    this.selectedLocation,
    this.onLocationSelected,
    this.onPackage,
    this.userLogo,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Drawer(
      child: SafeArea(
        child: Row(
          children: [
            // Left Column - Locations
            Expanded(
              child: Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    // Logo Bizflow
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Image.asset(
                        'assets/images/logos/Bizflow.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Locations List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        itemCount: widget.locations.length,
                        itemBuilder: (context, index) {
                          final location = widget.locations[index];
                          final isSelected =
                              widget.selectedLocation?.id == location.id;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                widget.onLocationSelected?.call(location);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondary.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusXs,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.divider,
                                  ),
                                ),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Location Logo
                                    Container(
                                      width: double.infinity,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusXs,
                                        ),
                                      ),
                                      child: location.logoUrl != null
                                          ? Image.asset(
                                              location.logoUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/images/logos/Bizflow.png',
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    // Location Name
                                    Text(
                                      location.name,
                                      style: AppTextStyles.labelSmall
                                          .copyWith(
                                        color: isSelected
                                            ? AppColors.secondary
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Add Location Button
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onAddLocation,
                          icon: const Icon(Icons.add),
                          label: Text(
                            l10n.translate('sidebar.add_location'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXs,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Column - Menu
            Container(
              width: 200,
              color: AppColors.background,
              child: Column(
                children: [
                  // User Logo/Avatar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.1),
                      ),
                      child: widget.userLogo != null
                          ? Image.asset(
                              widget.userLogo!,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/logos/Bizflow.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.info_outline,
                          label: l10n.translate('sidebar.guide'),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onGuide();
                          },
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _buildMenuItem(
                          context,
                          icon: Icons.card_membership,
                          label: l10n.translate('sidebar.package'),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onPackage?.call();
                          },
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _buildMenuItem(
                          context,
                          icon: Icons.settings,
                          label: l10n.translate('sidebar.account_settings'),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onAccountSettings();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLogout();
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(
                          l10n.translate('sidebar.logout'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXs,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.secondary,
        ),
        title: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
