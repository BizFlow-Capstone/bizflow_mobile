import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cache/sync_status_controller.dart';
import '../utils/date_formatter.dart';

class AppSyncStatusText extends StatelessWidget implements PreferredSizeWidget {
  final EdgeInsetsGeometry? padding;

  const AppSyncStatusText({super.key, this.padding});

  @override
  Size get preferredSize => const Size.fromHeight(18);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: SyncStatusController(),
      builder: (context, _) {
        final state = SyncStatusController().state;
        final String text;

        if (state.isSyncing) {
          text = l10n.translate('sync.syncing');
        } else if (state.lastUpdatedAt != null) {
          final time = DateFormatter.formatTime(state.lastUpdatedAt!);
          text = l10n.translate('sync.updated_at', params: {'time': time});
        } else {
          text = l10n.translate('sync.idle');
        }

        return Container(
          alignment: Alignment.centerRight,
          color: AppColors.white,
          width: double.infinity,
          padding:
              padding ??
              const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isSyncing
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                text,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
