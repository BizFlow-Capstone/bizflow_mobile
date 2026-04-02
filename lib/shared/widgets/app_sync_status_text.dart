import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cache/sync_status_controller.dart';
import '../utils/date_formatter.dart';

class AppSyncStatusText extends StatelessWidget implements PreferredSizeWidget {
  final EdgeInsetsGeometry? padding;

  /// When provided a refresh icon button is shown next to the status text.
  /// Register [onRefresh] on the controller via
  /// [SyncStatusController.setManualRefreshCallback] in your page's [initState]
  /// instead of passing it here if the widget is declared as `const`.
  const AppSyncStatusText({super.key, this.padding});

  @override
  Size get preferredSize => const Size.fromHeight(22);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: SyncStatusController(),
      builder: (context, _) {
        final state = SyncStatusController().state;
        final String text;

        if (state.hasError && !state.isSyncing) {
          text = l10n.translate('sync.failed');
        } else if (state.isSyncing) {
          text = l10n.translate('sync.syncing');
        } else if (state.lastUpdatedAt != null) {
          final time = DateFormatter.formatTime(state.lastUpdatedAt!);
          text = l10n.translate('sync.updated_at', params: {'time': time});
        } else {
          text = l10n.translate('sync.idle');
        }

        final hasRefreshCallback =
          SyncStatusController().hasManualRefreshCallback;

        return Container(
          alignment: Alignment.centerRight,
          color: AppColors.white,
          width: double.infinity,
          padding:
              padding ??
              const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 14,
                    icon: state.isSyncing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : const Icon(Icons.refresh_rounded),
                    color: AppColors.textSecondary,
                    tooltip: l10n.translate('sync.refresh'),
                    onPressed: state.isSyncing
                        ? null
                        : () async {
                            final controller = SyncStatusController();
                            if (hasRefreshCallback) {
                              controller.triggerManualRefresh();
                              return;
                            }

                            // Fallback behavior: update global sync state even
                            // when current page has not registered a callback.
                            controller.startSync();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 300),
                            );
                            controller.endSync(updatedAt: DateTime.now());
                          },
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.hasError && !state.isSyncing
                      ? AppColors.error
                      : (state.isSyncing ? AppColors.warning : AppColors.success),
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
