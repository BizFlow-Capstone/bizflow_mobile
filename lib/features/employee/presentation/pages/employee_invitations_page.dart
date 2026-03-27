import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/notification_realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../auth/presentation/navigation/post_auth_navigation.dart';
import '../../data/employee_repository.dart';
import '../../data/models/employee_invitation_dto.dart';

class EmployeeInvitationsPage extends StatefulWidget {
  final bool allowBack;

  const EmployeeInvitationsPage({super.key, this.allowBack = true});

  @override
  State<EmployeeInvitationsPage> createState() =>
      _EmployeeInvitationsPageState();
}

class _EmployeeInvitationsPageState extends State<EmployeeInvitationsPage> {
  late Future<List<EmployeeInvitationDto>> _invitationsFuture;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _invitationsFuture = _loadInvitations();
    _realtimeSubscription = NotificationRealtimeService.notificationStream
        .listen((payload) {
          if (_isInvitationEvent(payload)) {
            _refresh();
          }
        });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<List<EmployeeInvitationDto>> _loadInvitations() {
    return context.read<EmployeeRepository>().getPendingInvitations();
  }

  Future<void> _refresh() async {
    setState(() {
      _invitationsFuture = _loadInvitations();
    });
    await _invitationsFuture;
  }

  Future<void> _acceptInvitation(EmployeeInvitationDto invitation) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EmployeeRepository>().acceptInvitation(
        invitation,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.tr('invitation.accept_success'))),
      );
      await PostAuthNavigation.route(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _rejectInvitation(EmployeeInvitationDto invitation) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EmployeeRepository>().rejectInvitation(
        invitation,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.tr('invitation.reject_success'))),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _formatDate(BuildContext context, DateTime value) {
    return DateFormatter.formatDateTime(value);
  }

  bool _isInvitationEvent(Map<String, dynamic> payload) {
    final type =
        payload['type']?.toString().toLowerCase() ??
        payload['notificationType']?.toString().toLowerCase() ??
        '';
    final targetScreen =
        payload['targetScreen']?.toString().toLowerCase() ?? '';

    return type.contains('invite') ||
        targetScreen == 'employeeinvitations' ||
        targetScreen == 'employeeinvitationspage';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.tr('invitation.title')),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: widget.allowBack,
        leading: widget.allowBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.black,
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: FutureBuilder<List<EmployeeInvitationDto>>(
        future: _invitationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.tr('invitation.load_failed'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: Text(context.l10n.tr('common.retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          final invitations = snapshot.data ?? const <EmployeeInvitationDto>[];
          if (invitations.isEmpty) {
            return Center(child: Text(context.l10n.tr('invitation.empty')));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: invitations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.ownerName.isEmpty
                              ? context.l10n.tr('invitation.unknown_owner')
                              : invitation.ownerName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${context.l10n.tr('invitation.invited_at')}: ${_formatDate(context, invitation.invitedAt)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectInvitation(invitation),
                                child: Text(
                                  context.l10n.tr('invitation.reject'),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _acceptInvitation(invitation),
                                child: Text(
                                  context.l10n.tr('invitation.accept'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
