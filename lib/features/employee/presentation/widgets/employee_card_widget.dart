import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeeCardWidget extends StatelessWidget {
  final EmployeeEntity employee;
  final VoidCallback onActionTap;

  const EmployeeCardWidget({
    super.key,
    required this.employee,
    required this.onActionTap,
  });

  static const Set<String> _genericStatusLabels = {
    'active',
    'accepted',
    'accept',
    'accepted invitation',
    'da chap nhan',
    'đã chấp nhận',
    'đã chấp nhận lời mời',
    'pending',
    'inactive',
    'resigned',
    'terminated',
    'deleted',
    'rejected',
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Xử lý hiển thị thông tin liên lạc (Email hoặc Phone)
    final contactInfo = employee.email.isNotEmpty 
        ? employee.email 
        : employee.phone;

    // Màu sắc trạng thái
    final (Color statusColor, String defaultStatusText) = switch (employee.status) {
      EmployeeStatus.pending => (Colors.orange, t.translate('employee.tab_pending')),
      EmployeeStatus.rejected => (AppColors.error, t.translate('employee.status_rejected')),
      EmployeeStatus.inactive => (AppColors.textSecondary, t.translate('employee.status_inactive')),
      EmployeeStatus.active => (AppColors.success, t.translate('employee.tab_active')),
    };
    final rawStatusLabel = (employee.statusLabel ?? '').trim();
    final normalizedStatusLabel = rawStatusLabel
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
    final shouldUseServerStatusLabel =
      rawStatusLabel.isNotEmpty &&
      !_genericStatusLabels.contains(normalizedStatusLabel);
    final statusText = shouldUseServerStatusLabel
      ? rawStatusLabel
      : defaultStatusText;

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

    final startAtText = employee.startedAt != null
      ? DateFormatter.formatDate(employee.startedAt)
        : '--';
    final endAtText = employee.endedAt != null
      ? DateFormatter.formatDate(employee.endedAt)
        : '--';

    final effectiveEnd = employee.endedAt ?? DateTime.now();
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
      } else if (duration.inDays > 0) {
        durationText = t.translate(
          'employee.duration_day',
          params: {'days': duration.inDays.toString()},
        );
      } else if (duration.inHours > 0) {
        durationText = t.translate(
          'employee.duration_hour',
          params: {'hours': duration.inHours.toString()},
        );
      } else {
        durationText = t.translate('employee.duration_less_than_day');
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
