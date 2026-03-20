import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class EmployeeActionSheet extends StatelessWidget {
  final VoidCallback onViewDetail;
  final VoidCallback onAssign;
  final VoidCallback onUnassign;
  final VoidCallback onDelete;
  final bool showAssign;
  final bool showUnassign;
  final bool showDelete;

  const EmployeeActionSheet({
    super.key,
    required this.onViewDetail,
    required this.onAssign,
    required this.onUnassign,
    required this.onDelete,
    this.showAssign = true,
    this.showUnassign = true,
    this.showDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.visibility_outlined, color: AppColors.textPrimary),
              title: Text(
                t.translate('employee.view_employee_detail'),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                onViewDetail();
              },
            ),
            if (showAssign)
              ListTile(
                leading: const Icon(Icons.playlist_add_check_circle_outlined, color: AppColors.textPrimary),
                title: Text(
                  t.translate('employee.assign_employee'),
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onAssign();
                },
              ),
            if (showUnassign)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: AppColors.textPrimary),
                title: Text(
                  t.translate('employee.unassign_employee'),
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onUnassign();
                },
              ),
            if (showDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  t.translate('employee.delete_employee'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }
}
