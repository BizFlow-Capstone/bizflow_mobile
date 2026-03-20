import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeeCardWidget extends StatelessWidget {
  final EmployeeEntity employee;
  final VoidCallback onActionTap;

  const EmployeeCardWidget({
    super.key,
    required this.employee,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Xử lý hiển thị thông tin liên lạc (Email hoặc Phone)
    final contactInfo = employee.email.isNotEmpty 
        ? employee.email 
        : employee.phone;

    // Màu sắc trạng thái
    final (Color statusColor, String statusText) = switch (employee.status) {
      EmployeeStatus.pending => (Colors.orange, t.translate('employee.tab_pending')),
      EmployeeStatus.rejected => (AppColors.error, t.translate('employee.status_rejected')),
      EmployeeStatus.inactive => (AppColors.textSecondary, t.translate('employee.status_inactive')),
      EmployeeStatus.active => (AppColors.success, t.translate('employee.tab_active')),
    };

    String assignmentLabel;
    if (employee.assignedLocationNames.isEmpty) {
      assignmentLabel = t.translate('employee.assignment_unassigned');
    } else if (employee.assignedLocationNames.length == 1) {
      assignmentLabel = t.translate(
        'employee.assignment_single',
        params: {'location': employee.assignedLocationNames.first},
      );
    } else {
      assignmentLabel = t.translate(
        'employee.assignment_count',
        params: {'count': employee.assignedLocationNames.length.toString()},
      );
    }

    final dateFormatter = DateFormat('dd/MM/yyyy');
    final startAtText = employee.startedAt != null
        ? dateFormatter.format(employee.startedAt!.toLocal())
        : '--';
    final endAtText = employee.endedAt != null
        ? dateFormatter.format(employee.endedAt!.toLocal())
        : '--';

    final effectiveEnd = employee.endedAt ?? DateTime.now().toUtc();
    String durationText = '--';
    final shouldShowWorkedTimeline = employee.startedAt != null;
    if (employee.startedAt != null && effectiveEnd.isAfter(employee.startedAt!)) {
      final duration = effectiveEnd.difference(employee.startedAt!);
      final months = duration.inDays ~/ 30;
      final days = duration.inDays % 30;
      if (months > 0) {
        durationText = t.translate(
          'employee.duration_month_day',
          params: {'months': months.toString(), 'days': days.toString()},
        );
      } else {
        durationText = t.translate(
          'employee.duration_day',
          params: {'days': duration.inDays.toString()},
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Placeholder
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              radius: 20,
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contactInfo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignmentLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26), // 10% opacity
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (shouldShowWorkedTimeline) ...[
                    const SizedBox(height: 8),
                    Text(
                      t.translate('employee.worked_from_to', params: {
                        'start': startAtText,
                        'end': endAtText,
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      t.translate('employee.worked_duration', params: {'duration': durationText}),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action Button
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onPressed: onActionTap,
            ),
          ],
        ),
      ),
    );
  }
}
