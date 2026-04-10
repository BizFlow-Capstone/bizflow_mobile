import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';

/// Notification Detail Page
class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String? externalUrl;
  final String? notificationType;

  const NotificationDetailPage({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.externalUrl,
    this.notificationType,
  });

  String? _extractFirstUrl(String text) {
    final regex = RegExp(r'https?://[^\s)]+', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  String? get _resolvedExternalUrl {
    final direct = externalUrl?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final fromBody = _extractFirstUrl(body);
    if (fromBody != null && fromBody.isNotEmpty) {
      return fromBody;
    }
    return null;
  }

  Future<void> _launchUrl() async {
    final targetUrl = _resolvedExternalUrl;
    if (targetUrl == null || targetUrl.isEmpty) return;

    final Uri url = Uri.parse(targetUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $targetUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        title: Text(
          l10n.translate('notification.detail_title'),
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: Center(
                        child: Icon(icon, color: iconColor, size: 32),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      time,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),

              // External URL Button
              if (_resolvedExternalUrl != null &&
                  _resolvedExternalUrl!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _launchUrl,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.translate('notification.open_link')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
