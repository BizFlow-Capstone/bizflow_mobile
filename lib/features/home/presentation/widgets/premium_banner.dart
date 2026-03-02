import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Premium Upgrade Banner
class PremiumBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFFFFA500), Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Crown Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Text Content
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.translate('home.upgrade_premium'),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.translate('home.unlock_all_features'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Arrow Icon
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
