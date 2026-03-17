import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/localization_provider.dart';
import 'language_switcher.dart';
import 'sidebar_widget.dart';
import 'app_sync_status_text.dart';

/// Custom AppBar Component
/// Sử dụng cho các trang chính (Location, Product, etc.)
/// Chứa: Xin chào + tên, Đa ngôn ngữ, Thông báo, Cài đặt
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final Function(Locale)? onLocaleChange;
  final List<LocationItem>? locations;
  final VoidCallback? onAddLocation;
  final VoidCallback? onLogout;
  final VoidCallback? onGuide;
  final VoidCallback? onAccountSettings;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final int notificationCount;

  const CustomAppBar({
    super.key,
    this.userName,
    this.avatarUrl,
    this.onNotificationTap,
    this.onSettingsTap,
    this.onLocaleChange,
    this.locations,
    this.onAddLocation,
    this.onLogout,
    this.onGuide,
    this.onAccountSettings,
    this.scaffoldKey,
    this.notificationCount = 0,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(74);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      // Reduce padding - bring title closer to left
      titleSpacing: 0,
      // Remove back button (leading widget)
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () {
          // Open drawer - scaffoldKey comes from _GlobalAppBarShell in app_router
          if (widget.scaffoldKey != null) {
            widget.scaffoldKey!.currentState?.openDrawer();
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Avatar hoặc Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: (widget.avatarUrl != null &&
                          widget.avatarUrl!.trim().isNotEmpty)
                      ? Image.network(
                          widget.avatarUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Center(
                              child: Icon(
                                Icons.person,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.person,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Greeting + Name (Fixed width to prevent expansion)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.translate('appbar.greeting'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    widget.userName ?? 'User',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Language Switcher
        LanguageSwitcher(
          currentLocale: localizationProvider.currentLocale,
          onLanguageChanged: (locale) {
            localizationProvider.setLocale(locale);
          },
        ),
        // Notification with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: widget.onNotificationTap,
              icon: const Icon(Icons.notifications_none),
              color: AppColors.textPrimary,
            ),
            if (widget.notificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      widget.notificationCount > 9
                          ? '9+'
                          : '${widget.notificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Settings
        IconButton(
          onPressed: widget.onSettingsTap,
          icon: const Icon(Icons.settings),
          color: AppColors.textPrimary,
        ),
        SizedBox(width: AppSpacing.sm),
      ],
      bottom: const AppSyncStatusText(),
    );
  }
}
