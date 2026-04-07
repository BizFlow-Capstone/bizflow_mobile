import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/models/accounting_period.dart';
import '../bloc/accounting_period_bloc.dart';
import 'accounting_books_list_widget.dart';

class AccountingPeriodTab extends StatefulWidget {
  final String locationId;

  const AccountingPeriodTab({super.key, required this.locationId});

  @override
  State<AccountingPeriodTab> createState() => _AccountingPeriodTabState();
}

class _AccountingPeriodTabState extends State<AccountingPeriodTab> {
  List<AccountingPeriod> _cachedPeriods = const [];
  bool _isCreatePeriodSheetOpen = false;

  void _showSnackNow(ScaffoldMessengerState messenger, SnackBar snackBar) {
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    return BlocConsumer<AccountingPeriodBloc, AccountingPeriodState>(
      listenWhen: (prev, curr) =>
          (curr.status == AccountingPeriodStatus.actionSuccess &&
              prev.status != AccountingPeriodStatus.actionSuccess) ||
          (curr.status == AccountingPeriodStatus.error &&
              prev.status != AccountingPeriodStatus.error),
      listener: (context, state) {
        if (messenger == null) return;

        if (_isCreatePeriodSheetOpen &&
            state.status == AccountingPeriodStatus.error) {
          return;
        }

        if (state.status == AccountingPeriodStatus.actionSuccess &&
            state.actionSuccessKey != null) {
          _showSnackNow(
            messenger,
            SnackBar(
              content: Text(l10n.translate(state.actionSuccessKey!)),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.status == AccountingPeriodStatus.error &&
            state.errorMessage != null) {
          _showErrorSnack(messenger, state.errorMessage!, l10n);
        }
      },
      builder: (context, state) {
        // Determine list to display
        List<AccountingPeriod> periods = _cachedPeriods;
        bool isLoading = state.isListLoading && _cachedPeriods.isEmpty;
        bool isRefreshing = state.isRefreshing;

        if (state.status == AccountingPeriodStatus.loaded ||
            state.status == AccountingPeriodStatus.actionSuccess) {
          periods = state.periods;
          _cachedPeriods = state.periods;
        }

        if (state.status == AccountingPeriodStatus.error &&
            _cachedPeriods.isEmpty) {
          return _ErrorView(
            message:
                state.errorMessage ?? l10n.translate('common.unknown_error'),
            onRetry: () => context.read<AccountingPeriodBloc>().add(
              LoadPeriodsRequested(widget.locationId),
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: isLoading
                      ? _LoadingView(l10n: l10n)
                      : periods.isEmpty
                      ? _EmptyView(l10n: l10n)
                      : _PeriodList(
                          periods: periods,
                          locationId: widget.locationId,
                          l10n: l10n,
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: AppSpacing.xl,
              right: AppSpacing.md,
              child: FloatingActionButton.extended(
                heroTag: 'create_period_fab',
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                onPressed: () => _showCreatePeriodSheet(
                  context,
                  widget.locationId,
                  l10n,
                  messenger: messenger,
                  isFirstPeriod: periods.isEmpty,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.translate('accounting.create_new_period')),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnack(
    ScaffoldMessengerState? messenger,
    String rawMessage,
    AppLocalizations l10n,
  ) {
    if (messenger == null) return;
    String userMessage;
    if (rawMessage.contains('period_already_exists')) {
      userMessage = l10n.translate('accounting.period_already_exists');
    } else if (rawMessage.contains('period_no_books')) {
      userMessage = l10n.translate('accounting.period_no_books');
    } else if (rawMessage.contains('reopen_reason_required')) {
      userMessage = l10n.translate('accounting.reopen_reason_required');
    } else if (rawMessage.contains('period_already_finalized')) {
      userMessage = l10n.translate('accounting.period_status_finalized');
    } else if (rawMessage.contains('PERIOD_OPENING_BALANCE_REQUIRED') ||
        rawMessage.contains('Kỳ đầu tiên bắt buộc')) {
      userMessage = l10n.translate(
        'accounting.first_period_opening_balance_required',
      );
    } else {
      userMessage = rawMessage;
    }
    _showSnackNow(
      messenger,
      SnackBar(content: Text(userMessage), backgroundColor: AppColors.error),
    );
  }

  Future<void> _showCreatePeriodSheet(
    BuildContext context,
    String locationId,
    AppLocalizations l10n, {
    required ScaffoldMessengerState? messenger,
    required bool isFirstPeriod,
  }) async {
    if (!context.mounted) return;
    final bloc = context.read<AccountingPeriodBloc>();
    setState(() => _isCreatePeriodSheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _CreatePeriodSheet(
          locationId: locationId,
          l10n: l10n,
          messenger: messenger,
          isFirstPeriod: isFirstPeriod,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _isCreatePeriodSheetOpen = false);
  }
}

// ─────────────────────── PERIOD LIST ───────────────────────

class _PeriodList extends StatelessWidget {
  final List<AccountingPeriod> periods;
  final String locationId;
  final AppLocalizations l10n;

  const _PeriodList({
    required this.periods,
    required this.locationId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AccountingPeriodBloc>().add(
          LoadPeriodsRequested(locationId),
        );
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          return _PeriodCard(
            period: periods[index],
            locationId: locationId,
            l10n: l10n,
          );
        },
      ),
    );
  }
}

// ─────────────────────── PERIOD CARD ───────────────────────

class _PeriodCard extends StatelessWidget {
  final AccountingPeriod period;
  final String locationId;
  final AppLocalizations l10n;

  const _PeriodCard({
    required this.period,
    required this.locationId,
    required this.l10n,
  });

  Color _statusColor() {
    switch (period.status) {
      case 'finalized':
        return AppColors.error;
      case 'reopened':
        return Colors.orange;
      default:
        return AppColors.success;
    }
  }

  String _statusLabel() {
    return _statusText(period.status);
  }

  String _statusText(String status) {
    switch (status) {
      case 'finalized':
        return l10n.translate('accounting.period_status_finalized');
      case 'reopened':
        return l10n.translate('accounting.period_status_reopened');
      default:
        return l10n.translate('accounting.period_status_open');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isActionLoading = context.select(
      (AccountingPeriodBloc bloc) => bloc.state.isActionLoading,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => _showPeriodDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      period.displayLabel,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        color: _statusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.translate("accounting.start_date")}: ${period.startDate}  •  ${l10n.translate("accounting.end_date")}: ${period.endDate}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (period.openingCashBalance != null ||
                  period.openingBankBalance != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${l10n.translate("accounting.opening_cash_balance")}: ${formatter.format(period.openingCashBalance ?? 0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    // Audit log button
                    TextButton.icon(
                      onPressed: () => _showAuditLog(context),
                      icon: const Icon(Icons.history, size: 16),
                      label: Text(
                        l10n.translate('accounting.action_view_audit'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                    ),
                    // Create Books button (if period is open)
                    if (period.isOpen)
                      TextButton.icon(
                        onPressed: isActionLoading
                            ? null
                            : () => _showCreateBooksDialog(context),
                        icon: const Icon(Icons.book_outlined, size: 16),
                        label: Text(
                          l10n.translate('accounting.action_create_books'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                    // Finalize / Reopen button
                    if (period.isOpen)
                      TextButton.icon(
                        onPressed: isActionLoading
                            ? null
                            : () => _confirmFinalize(context),
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: Text(
                          l10n.translate('accounting.action_finalize'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      )
                    else if (period.isFinalized)
                      TextButton.icon(
                        onPressed: isActionLoading
                            ? null
                            : () => _confirmReopen(context),
                        icon: const Icon(Icons.lock_open_outlined, size: 16),
                        label: Text(
                          l10n.translate('accounting.action_reopen'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmFinalize(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.translate('accounting.finalize_period'),
      message: l10n.translate('accounting.confirm_finalize'),
      confirmText: l10n.translate('accounting.action_finalize'),
      cancelText: l10n.translate('common.cancel'),
    );
    if (confirmed == true && context.mounted) {
      context.read<AccountingPeriodBloc>().add(
        FinalizePeriodRequested(
          locationId: locationId,
          periodId: period.periodId.toString(),
        ),
      );
    }
  }

  Future<void> _confirmReopen(BuildContext context) async {
    final reasonController = TextEditingController();
    String? validationError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(l10n.translate('accounting.reopen_period')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('accounting.confirm_reopen')),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.reopen_reason'),
                  hintText: l10n.translate('accounting.reopen_reason_hint'),
                  errorText: validationError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setStateDialog(() => validationError = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  setStateDialog(() {
                    validationError = l10n.translate(
                      'accounting.reopen_reason_required',
                    );
                  });
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(l10n.translate('accounting.action_reopen')),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AccountingPeriodBloc>().add(
        ReopenPeriodRequested(
          locationId: locationId,
          periodId: period.periodId.toString(),
          reason: reasonController.text.trim(),
        ),
      );
    }
    reasonController.dispose();
  }

  Future<void> _showAuditLog(BuildContext context) async {
    if (!context.mounted) return;
    final bloc = context.read<AccountingPeriodBloc>();

    bloc.add(
      LoadAuditLogsRequested(
        locationId: locationId,
        periodId: period.periodId.toString(),
      ),
    );

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _AuditLogSheet(periodLabel: period.displayLabel, l10n: l10n),
      ),
    );
  }

  void _showPeriodDetail(BuildContext context) {
    if (!context.mounted) return;
    final bloc = context.read<AccountingPeriodBloc>();

    bloc.add(
      LoadPeriodDetailRequested(
        locationId: locationId,
        periodId: period.periodId.toString(),
      ),
    );

    // Load books for this period
    bloc.add(
      LoadBooksForPeriodRequested(
        locationId: locationId,
        periodId: period.periodId,
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _PeriodDetailSheet(
          periodLabel: period.displayLabel,
          l10n: l10n,
          locationId: locationId,
        ),
      ),
    );
  }

  Future<void> _showCreateBooksDialog(BuildContext context) async {
    if (!context.mounted) return;

    String? selectedGroup;
    late int groupNumber;
    late String taxMethod;
    late List<String> templateCodes;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(l10n.translate('accounting.create_accounting_books')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('accounting.select_accounting_group')),
              const SizedBox(height: AppSpacing.md),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedGroup,
                hint: Text(l10n.translate('accounting.select_group')),
                items: [
                  DropdownMenuItem(
                    value: 'group1',
                    child: Text(
                      '${l10n.translate("accounting.group")} 1 - Exempt (S1a)',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'group2_m1',
                    child: Text(
                      '${l10n.translate("accounting.group")} 2 - ${l10n.translate("accounting.method")} 1 (S2a)',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'group234_m2',
                    child: Text(
                      '${l10n.translate("accounting.group")} 2-4 - ${l10n.translate("accounting.method")} 2 (S2b+S2c+S2d+S2e)',
                    ),
                  ),
                ],
                onChanged: (value) {
                  setStateDialog(() => selectedGroup = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: selectedGroup == null
                  ? null
                  : () {
                      // Map selection to group/method/templates
                      switch (selectedGroup) {
                        case 'group1':
                          groupNumber = 1;
                          taxMethod = 'exempt';
                          templateCodes = ['S1a'];
                          break;
                        case 'group2_m1':
                          groupNumber = 2;
                          taxMethod = 'method_1';
                          templateCodes = ['S2a'];
                          break;
                        case 'group234_m2':
                          groupNumber =
                              2; // default group 2; user adjust if needed
                          taxMethod = 'method_2';
                          templateCodes = ['S2b', 'S2c', 'S2d', 'S2e'];
                          break;
                      }
                      Navigator.pop(ctx, true);
                    },
              child: Text(l10n.translate('common.create')),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AccountingPeriodBloc>().add(
        CreateBooksRequested(
          locationId: locationId,
          periodId: period.periodId,
          groupNumber: groupNumber,
          taxMethod: taxMethod,
          templateCodes: templateCodes,
        ),
      );
    }
  }
}

// ─────────────────────── AUDIT LOG SHEET ───────────────────────

class _AuditLogSheet extends StatelessWidget {
  final String periodLabel;
  final AppLocalizations l10n;

  const _AuditLogSheet({required this.periodLabel, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Column(
          children: [
            // Handle + header
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '${l10n.translate("accounting.audit_log")} • $periodLabel',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<AccountingPeriodBloc, AccountingPeriodState>(
                builder: (context, state) {
                  if (state.isLogsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = state.auditLogs;
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.translate('accounting.audit_log_empty'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: logs.length,
                    itemBuilder: (_, i) =>
                        _AuditLogItem(log: logs[i], l10n: l10n),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  final AccountingPeriodAuditLog log;
  final AppLocalizations l10n;

  const _AuditLogItem({required this.log, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.formatDateTime(log.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
              Container(width: 2, height: 40, color: Colors.grey[200]),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _auditActionLabel(log.action),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (log.reason != null && log.reason!.isNotEmpty)
                  Text(log.reason!, style: AppTextStyles.bodySmall),
                Text(
                  dateStr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _auditActionLabel(String action) {
    // Try to translate action name, fallback to human-readable version
    final key = 'accounting.action_${action.toLowerCase()}';
    final translated = l10n.translate(key);
    if (translated != key) return translated;
    return action.replaceAll('_', ' ').toUpperCase();
  }
}

// ─────────────────────── PERIOD DETAIL SHEET ───────────────────────

class _PeriodDetailSheet extends StatefulWidget {
  final String periodLabel;
  final AppLocalizations l10n;
  final String locationId;

  const _PeriodDetailSheet({
    required this.periodLabel,
    required this.l10n,
    required this.locationId,
  });

  @override
  State<_PeriodDetailSheet> createState() => _PeriodDetailSheetState();
}

class _PeriodDetailSheetState extends State<_PeriodDetailSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '${widget.l10n.translate("accounting.period_detail")} • ${widget.periodLabel}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: widget.l10n.translate('accounting.period_info')),
                Tab(text: widget.l10n.translate('accounting.books')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Period Info Tab
                  _buildPeriodInfoTab(context, currency, controller),
                  // Books Tab
                  _buildBooksTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInfoTab(
    BuildContext context,
    NumberFormat currency,
    ScrollController controller,
  ) {
    return BlocBuilder<AccountingPeriodBloc, AccountingPeriodState>(
      builder: (context, state) {
        if (state.isDetailLoading && state.periodDetail == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show loading overlay when an action (finalize/reopen) is in progress
        if (state.isActionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final period = state.periodDetail;
        if (period != null) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (state.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              _DetailRow(
                label: widget.l10n.translate('accounting.period_type_label'),
                value: _periodTypeLabel(period.periodType),
              ),
              _DetailRow(
                label: widget.l10n.translate('accounting.select_year'),
                value: period.year.toString(),
              ),
              if (period.quarter != null)
                _DetailRow(
                  label: widget.l10n.translate('accounting.select_quarter'),
                  value: 'Q${period.quarter}',
                ),
              _DetailRow(
                label: widget.l10n.translate('accounting.start_date'),
                value: period.startDate,
              ),
              _DetailRow(
                label: widget.l10n.translate('accounting.end_date'),
                value: period.endDate,
              ),
              _DetailRow(
                label: widget.l10n.translate('accounting.opening_cash_balance'),
                value: currency.format(period.openingCashBalance ?? 0),
              ),
              _DetailRow(
                label: widget.l10n.translate('accounting.opening_bank_balance'),
                value: currency.format(period.openingBankBalance ?? 0),
              ),
              _DetailRow(
                label: widget.l10n.translate('common.status'),
                value: _statusLabel(period.status),
                valueColor: period.isOpen ? AppColors.success : AppColors.error,
              ),
            ],
          );
        }

        if (state.status == AccountingPeriodStatus.error &&
            state.periodDetail == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                state.errorMessage ??
                    widget.l10n.translate('common.unknown_error'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildBooksTab(BuildContext context) {
    return BlocBuilder<AccountingPeriodBloc, AccountingPeriodState>(
      builder: (context, state) {
        if (state.isBooksLoading && state.books.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = state.books;
        final locationId = _getLocationIdFromContext(context);

        if (books.isNotEmpty) {
          return AccountingBooksListWidget(
            books: books,
            locationId: locationId,
            isLoading: state.isRefreshing,
            onRefresh: () {
              // Can be used to manually refresh
            },
          );
        }

        if (state.status == AccountingPeriodStatus.error &&
            state.books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                state.errorMessage ??
                    widget.l10n.translate('common.unknown_error'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.l10n.translate('accounting.period_no_books'),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLocationIdFromContext(BuildContext context) {
    // This should be extracted from parent widget context
    // For now, return empty - will be fixed in next step
    return widget.locationId;
  }

  String _periodTypeLabel(String type) {
    switch (type) {
      case 'quarter':
        return widget.l10n.translate('accounting.period_quarter');
      case 'year':
        return widget.l10n.translate('accounting.period_year');
      case 'custom':
        return widget.l10n.translate('accounting.period_custom');
      default:
        return type;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'finalized':
        return widget.l10n.translate('accounting.period_status_finalized');
      case 'reopened':
        return widget.l10n.translate('accounting.period_status_reopened');
      default:
        return widget.l10n.translate('accounting.period_status_open');
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── CREATE PERIOD SHEET ───────────────────────

class _CreatePeriodSheet extends StatefulWidget {
  final String locationId;
  final AppLocalizations l10n;
  final ScaffoldMessengerState? messenger;
  final bool isFirstPeriod;

  const _CreatePeriodSheet({
    required this.locationId,
    required this.l10n,
    required this.messenger,
    required this.isFirstPeriod,
  });

  @override
  State<_CreatePeriodSheet> createState() => _CreatePeriodSheetState();
}

class _CreatePeriodSheetState extends State<_CreatePeriodSheet> {
  String _periodType = 'quarter';
  int _year = DateTime.now().year;
  int _quarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime(DateTime.now().year, 3, 31);

  final _cashController = TextEditingController();
  final _bankController = TextEditingController();

  bool _useSuggestion = false;
  bool _loadingSuggestion = false;
  bool _isSubmitting = false;
  bool _isWaitingCreateResult = false;
  String? _submitErrorMessage;

  AppLocalizations get l10n => widget.l10n;

  String _requiredLabel(String label) => '$label *';

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestion() async {
    setState(() => _loadingSuggestion = true);
    context.read<AccountingPeriodBloc>().add(
      FetchSuggestionRequested(
        locationId: widget.locationId,
        periodType: _periodType,
        year: _periodType != 'custom' ? _year : null,
        quarter: _periodType == 'quarter' ? _quarter : null,
        startDate: _periodType == 'custom'
            ? DateFormatter.formatIso(_startDate)
            : null,
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _setSubmitError(String? message) {
    if (!mounted) return;
    setState(() {
      _submitErrorMessage = message;
    });
  }

  void _submit() {
    if (_isSubmitting) return;

    if (_periodType == 'quarter' && (_quarter < 1 || _quarter > 4)) {
      _setSubmitError(l10n.translate('common.required'));
      return;
    }

    final cash = CurrencyFormatter.parse(_cashController.text)?.toDouble();
    final bank = CurrencyFormatter.parse(_bankController.text)?.toDouble();

    if (widget.isFirstPeriod && (cash == null || bank == null)) {
      _setSubmitError(
        l10n.translate('accounting.first_period_opening_balance_required'),
      );
      return;
    }

    if (_periodType == 'custom' && _endDate.isBefore(_startDate)) {
      _setSubmitError(
        l10n.translate('accounting.custom_end_date_must_be_after_start'),
      );
      return;
    }

    _setSubmitError(null);
    setState(() {
      _isSubmitting = true;
      _isWaitingCreateResult = false;
    });

    final bloc = context.read<AccountingPeriodBloc>();

    if (_periodType == 'custom') {
      bloc.add(
        CreateCustomPeriodRequested(
          locationId: widget.locationId,
          startDate: DateFormatter.formatIso(_startDate),
          endDate: DateFormatter.formatIso(_endDate),
          openingCashBalance: cash,
          openingBankBalance: bank,
          useSuggestedOpeningBalances: _useSuggestion,
        ),
      );
    } else {
      bloc.add(
        CreatePeriodRequested(
          locationId: widget.locationId,
          periodType: _periodType == 'quarter' ? 'quarter' : 'year',
          year: _year,
          quarter: _periodType == 'quarter' ? _quarter : null,
          openingCashBalance: cash,
          openingBankBalance: bank,
          useSuggestedOpeningBalances: _useSuggestion,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountingPeriodBloc, AccountingPeriodState>(
      listenWhen: (prev, curr) =>
          prev.suggestion != curr.suggestion ||
          prev.status != curr.status ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (!mounted) return;

        if (_isSubmitting && state.isActionLoading) {
          if (!_isWaitingCreateResult) {
            setState(() => _isWaitingCreateResult = true);
          }
          return;
        }

        if (state.status == AccountingPeriodStatus.actionSuccess) {
          if (!_isSubmitting || !_isWaitingCreateResult) {
            return;
          }
          setState(() {
            _isSubmitting = false;
            _isWaitingCreateResult = false;
          });
          Navigator.pop(context);
          return;
        }

        if (state.status == AccountingPeriodStatus.error) {
          if (!_isSubmitting || !_isWaitingCreateResult) {
            return;
          }
          setState(() {
            _isSubmitting = false;
            _isWaitingCreateResult = false;
          });
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _setSubmitError(state.errorMessage);
          }
          return;
        }

        final suggestion = state.suggestion;
        if (suggestion != null) {
          setState(() {
            _loadingSuggestion = false;
            if (suggestion.hasSuggestion) {
              _cashController.text = CurrencyFormatter.formatNumber(
                suggestion.openingCashBalance ?? 0,
              );
              _bankController.text = CurrencyFormatter.formatNumber(
                suggestion.openingBankBalance ?? 0,
              );
              _useSuggestion = true;
            } else {
              if (!mounted) return;
              final messenger = widget.messenger;
              if (messenger != null) {
                messenger.removeCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('accounting.no_suggestion')),
                  ),
                );
              }
            }
          });
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('accounting.create_period_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Type Selector
                      Text(
                        _requiredLabel(
                          l10n.translate('accounting.period_type_label'),
                        ),
                        style: AppTextStyles.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _TypeChip(
                            label: l10n.translate('accounting.period_quarter'),
                            selected: _periodType == 'quarter',
                            onTap: () =>
                                setState(() => _periodType = 'quarter'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _TypeChip(
                            label: l10n.translate('accounting.period_year'),
                            selected: _periodType == 'year',
                            onTap: () => setState(() => _periodType = 'year'),
                          ),
                          _TypeChip(
                            label: l10n.translate('accounting.period_custom'),
                            selected: _periodType == 'custom',
                            onTap: () => setState(() => _periodType = 'custom'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Year picker (always shown)
                      if (_periodType != 'custom') ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 420;
                            final yearField = DropdownButtonFormField<int>(
                              initialValue: _year,
                              decoration: InputDecoration(
                                labelText: _requiredLabel(
                                  l10n.translate('accounting.select_year'),
                                ),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items: List.generate(
                                6,
                                (i) => DropdownMenuItem(
                                  value: 2023 + i,
                                  child: Text('${2023 + i}'),
                                ),
                              ),
                              onChanged: (v) {
                                if (v != null) setState(() => _year = v);
                              },
                            );

                            if (_periodType != 'quarter') {
                              return yearField;
                            }

                            final quarterField = DropdownButtonFormField<int>(
                              initialValue: _quarter,
                              decoration: InputDecoration(
                                labelText: _requiredLabel(
                                  l10n.translate('accounting.select_quarter'),
                                ),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text(
                                    l10n.translate('accounting.quarter_1'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text(
                                    l10n.translate('accounting.quarter_2'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text(
                                    l10n.translate('accounting.quarter_3'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text(
                                    l10n.translate('accounting.quarter_4'),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _quarter = v);
                              },
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  yearField,
                                  const SizedBox(height: AppSpacing.sm),
                                  quarterField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: yearField),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: quarterField),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        // Custom date range
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 420;
                            final startField = _DatePickerField(
                              label: _requiredLabel(
                                l10n.translate('accounting.start_date'),
                              ),
                              date: _startDate,
                              onTap: () => _pickDate(isStart: true),
                            );
                            final endField = _DatePickerField(
                              label: _requiredLabel(
                                l10n.translate('accounting.end_date'),
                              ),
                              date: _endDate,
                              onTap: () => _pickDate(isStart: false),
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  startField,
                                  const SizedBox(height: AppSpacing.sm),
                                  endField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: startField),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: endField),
                              ],
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Opening balances
                      TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        inputFormatters:
                            AppInputFormatters.withSqlInjectionGuard(
                              inputFormatters: [CurrencyInputFormatter()],
                            ),
                        decoration: InputDecoration(
                          labelText: l10n.translate(
                            'accounting.opening_cash_balance',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _bankController,
                        keyboardType: TextInputType.number,
                        inputFormatters:
                            AppInputFormatters.withSqlInjectionGuard(
                              inputFormatters: [CurrencyInputFormatter()],
                            ),
                        decoration: InputDecoration(
                          labelText: l10n.translate(
                            'accounting.opening_bank_balance',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Suggestion button
                      OutlinedButton.icon(
                        onPressed: _loadingSuggestion ? null : _fetchSuggestion,
                        icon: _loadingSuggestion
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_fix_high, size: 18),
                        label: Text(
                          l10n.translate('accounting.get_balance_suggestion'),
                        ),
                      ),

                      if (_useSuggestion) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.translate('accounting.suggestion_loaded'),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Submit button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_submitErrorMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _submitErrorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  l10n.translate(
                                    'accounting.create_period_title',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── HELPER WIDGETS ───────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.secondary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.secondary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          DateFormatter.formatDate(date),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

// ─────────────────────── EMPTY / LOADING / ERROR VIEWS ───────────────────────

class _LoadingView extends StatelessWidget {
  final AppLocalizations l10n;
  const _LoadingView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.translate('accounting.loading_periods')),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('accounting.period_list_empty'),
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.translate('accounting.period_list_empty_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).translate('common.retry')),
          ),
        ],
      ),
    );
  }
}
