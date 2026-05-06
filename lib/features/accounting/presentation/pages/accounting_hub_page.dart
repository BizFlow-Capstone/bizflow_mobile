import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:bizflow_mobile/core/reference/presentation/bloc/reference_bloc.dart';
import 'package:bizflow_mobile/core/reference/presentation/bloc/reference_event.dart';
import 'package:bizflow_mobile/core/reference/presentation/bloc/reference_state.dart';
import 'package:bizflow_mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:bizflow_mobile/features/order/presentation/pages/order_detail_screen.dart';
import 'package:bizflow_mobile/features/revenue/presentation/bloc/revenue_bloc.dart';
import 'package:bizflow_mobile/features/cost/presentation/bloc/cost_bloc.dart';
import 'package:bizflow_mobile/features/product/data/import_repository.dart';
import 'package:bizflow_mobile/features/product/data/models/business_type_model.dart';
import 'package:bizflow_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:bizflow_mobile/features/revenue/domain/entities/revenue_entity.dart';
import 'package:bizflow_mobile/features/cost/domain/entities/cost_entity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_bottom_sheet.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/cache/sync_status_controller.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/cache/local_api_cache_store.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../bloc/accounting_period_bloc.dart';
import '../bloc/gl_bloc/gl_bloc.dart';
import '../bloc/gl_bloc/gl_event.dart';
import '../bloc/gl_bloc/gl_state.dart';
import '../dialogs/ai_draft_cost_dialog.dart';
import '../dialogs/ai_draft_revenue_dialog.dart';
import '../widgets/accounting_cost_revenue_tab.dart';
import '../widgets/accounting_gl_tab.dart';
import '../widgets/accounting_period_tab.dart';
import '../../../accounting/domain/utils/accounting_reference_display.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/services/document_number_check_helper.dart';

class AccountingHubPage extends StatefulWidget {
  final int initialTabIndex;

  const AccountingHubPage({super.key, this.initialTabIndex = 0});

  @override
  State<AccountingHubPage> createState() => _AccountingHubPageState();
}

class _AccountingHubPageState extends State<AccountingHubPage>
    with SingleTickerProviderStateMixin {
  static const String _featureManualRevenue =
      SubscriptionFeatureCodes.manualRevenue;
  static const String _featureAi = SubscriptionFeatureCodes.ai;

  late final TabController _tabController;
  StreamSubscription? _periodSubscription;

  // Helper method: Check if date falls within a finalized period
  bool _isDateInFinalizedPeriod(DateTime date) {
    try {
      final periodBloc = context.read<AccountingPeriodBloc>();
      final periodState = periodBloc.state;

      final periods = periodState.periods;
      for (final period in periods) {
        if (period.isFinalized) {
          final start = DateTime.parse(period.startDate);
          final end = DateTime.parse(period.endDate);
          if (date.isAfter(start.subtract(const Duration(days: 1))) &&
              date.isBefore(end.add(const Duration(days: 1)))) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  bool _canModifyRevenueEntry(RevenueEntity item) {
    final sc = (item.statusCode ?? '').trim().toLowerCase();
    if (sc == 'replaced' || sc == 'cancelled') {
      return false;
    }
    if (!_isManualRevenueEntry(item)) return false;
    if (_isDateInFinalizedPeriod(item.date)) return false;
    return true;
  }

  bool _canModifyCostEntry(CostEntity item) {
    final sc = (item.statusCode ?? '').trim().toLowerCase();
    if (sc == 'replaced' || sc == 'cancelled') {
      return false;
    }
    if (!_isManualCostEntry(item)) return false;
    if (_isDateInFinalizedPeriod(item.date)) return false;
    return true;
  }

  // Period BLoC data is managed by AccountingPeriodBloc
  // Other tabs still use local/mock state for now
  final AudioRecorder _voiceRecorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  bool _isVoiceRecording = false;
  String? _lastVoicePath;
  String? _lastVoiceTranscript;
  List<RevenueEntity> _cachedRevenues = const <RevenueEntity>[];
  List<CostEntity> _cachedCosts = const <CostEntity>[];
  bool _suppressNextRevenueError = false;
  // Pagination trackers for revenue & cost tabs
  int _revenuePageNumber = 0;
  int _revenuePageSize = 20;
  bool _isLoadingMoreRevenue = false;

  int _costPageNumber = 0;
  int _costPageSize = 20;
  bool _isLoadingMoreCost = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    final safeInitialIndex = widget.initialTabIndex.clamp(0, 3).toInt();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: safeInitialIndex,
    );
    SyncStatusController().clearError();
    SyncStatusController().setManualRefreshCallback(_refreshCurrentTab);

    _tabController.addListener(_handleTabSelection);

    // Listen for accounting period detail changes so revenue/cost tabs reload
    // automatically when the selected period changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final periodBloc = context.read<AccountingPeriodBloc>();
        _periodSubscription = periodBloc.stream.listen((state) {
          if (!mounted) return;
          final periodDetail = state.periodDetail;
          if (periodDetail == null) return;

          final locationId = context.read<BusinessContext>().currentBusinessId;
          if (locationId == null) return;

          // If user is viewing revenue or cost tab, reload with period date range
          if (_tabController.index == 2) {
            try {
              final fromDate = DateTime.parse(periodDetail.startDate);
              final toDate = DateTime.parse(periodDetail.endDate);
              context.read<RevenueBloc>().add(
                LoadRevenuesRequested(
                  businessLocationId: locationId,
                  fromDate: fromDate,
                  toDate: toDate,
                ),
              );
            } catch (_) {}
          } else if (_tabController.index == 3) {
            try {
              final fromDate = DateTime.parse(periodDetail.startDate);
              final toDate = DateTime.parse(periodDetail.endDate);
              context.read<CostBloc>().add(
                LoadCostsRequested(
                  businessLocationId: locationId,
                  fromDate: fromDate,
                  toDate: toDate,
                ),
              );
            } catch (_) {}
          }
        });
      } catch (_) {}
    });

    // Initial load of first tab and references only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTab(safeInitialIndex);
      _loadReferences();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadTab(_tabController.index);
    }
  }

  void _loadTab(int index) {
    final locationId = context.read<BusinessContext>().currentBusinessId;
    if (locationId == null) return;

    switch (index) {
      case 0: // Kỳ kế toán
        context.read<AccountingPeriodBloc>().add(
          LoadPeriodsRequested(locationId),
        );
        break;
      case 1: // Sổ cái
        final locationIdInt = int.tryParse(locationId);
        if (locationIdInt == null || locationIdInt <= 0) {
          return;
        }

        final glState = context.read<GLBloc>().state;
        if (glState is GLLoaded) {
          context.read<GLBloc>().add(
            LoadGLEntriesRequested(
              businessLocationId: locationIdInt,
              pageNumber: 1,
              pageSize: glState.pageSize,
              transactionTypes: glState.transactionTypes,
              referenceTypes: glState.referenceTypes,
              moneyChannels: glState.moneyChannels,
              fromDate: glState.fromDate,
              toDate: glState.toDate,
              viewMode: glState.viewMode,
            ),
          );
        } else {
          context.read<GLBloc>().add(
            LoadGLEntriesRequested(
              businessLocationId: locationIdInt,
              pageNumber: 1,
              pageSize: 20,
            ),
          );
        }
        break;
      case 2: // Doanh thu
        setState(() {
          _revenuePageNumber = 0; // Reset to initial state
          _isLoadingMoreRevenue = false;
        });
        context.read<RevenueBloc>().add(
          LoadRevenuesRequested(businessLocationId: locationId),
        );
        break;
      case 3: // Chi phí
        setState(() {
          _costPageNumber = 0; // Reset to initial state
          _isLoadingMoreCost = false;
        });
        if (context.mounted) {
          context.read<CostBloc>().add(
            LoadCostsRequested(businessLocationId: locationId),
          );
        }
        break;
      // Tab 1 (Nhật ký/Sổ cái) is handled by AccountingGlTab internally or we could add triggering logic here later
    }
  }

  void _loadReferences() {
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }
  }

  void _refreshCurrentTab() {
    unawaited(_refreshCurrentTabAsync());
  }

  Future<void> _refreshCurrentTabAsync() async {
    if (!mounted) return;

    SyncStatusController().startSync();
    try {
      _loadReferences();

      // Force SWR revalidate for manual refresh — clear caches for all accounting
      // related lists so user-initiated refresh always reloads latest data.
      await CacheManager().removeByPrefix('gl_entries_');
      await LocalApiCacheStore().removeByGroup('gl_entries');
      await CacheManager().removeByPrefix('revenues_');
      await LocalApiCacheStore().removeByGroup('revenues');
      await CacheManager().removeByPrefix('costs_');
      await LocalApiCacheStore().removeByGroup('costs');

      _loadTab(_tabController.index);
      SyncStatusController().endSync(updatedAt: DateTime.now());
    } catch (_) {
      SyncStatusController().endSync(hasError: true);
    }
  }

  void _loadMoreRevenues() {
    if (_isLoadingMoreRevenue) return;
    final nextPage = (_revenuePageNumber <= 0) ? 2 : _revenuePageNumber + 1;
    setState(() => _isLoadingMoreRevenue = true);
    context.read<RevenueBloc>().add(
      LoadRevenuesRequested(
        pageNumber: nextPage,
        pageSize: _revenuePageSize,
        businessLocationId: context.read<BusinessContext>().currentBusinessId,
        isLoadMore: true,
      ),
    );
  }

  void _loadMoreCosts() {
    if (_isLoadingMoreCost) return;
    final nextPage = (_costPageNumber <= 0) ? 2 : _costPageNumber + 1;
    setState(() => _isLoadingMoreCost = true);
    context.read<CostBloc>().add(
      LoadCostsRequested(
        pageNumber: nextPage,
        pageSize: _costPageSize,
        businessLocationId: context.read<BusinessContext>().currentBusinessId,
        isLoadMore: true,
      ),
    );
  }

  @override
  void dispose() {
    SyncStatusController().setManualRefreshCallback(null);
    _voiceRecorder.dispose();
    _voicePlayer.dispose();
    _tabController.dispose();
    try {
      _periodSubscription?.cancel();
    } catch (_) {}
    super.dispose();
  }

  Future<String?> _toggleVoiceCapture() async {
    if (_isVoiceRecording) {
      final recordedPath = await _voiceRecorder.stop();
      if (recordedPath == null || recordedPath.isEmpty) {
        if (mounted) {
          AppDialog.error(
            context,
            title: l10n.translate('common.error'),
            message: l10n.translate('accounting.voice_no_record_found'),
          );
        }
        setState(() => _isVoiceRecording = false);
        return null;
      }

      setState(() {
        _isVoiceRecording = false;
        _lastVoicePath = recordedPath;
      });

      // Mock AI transcription to keep current business flow unchanged.
      await Future.delayed(const Duration(milliseconds: 900));
      final transcript = _mockTranscribeVoice();
      setState(() => _lastVoiceTranscript = transcript);
      return transcript;
    }

    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      if (mounted) {
        AppDialog.error(
          context,
          title: l10n.translate('common.error'),
          message: l10n.translate('common.microphone_permission_required'),
        );
      }
      return null;
    }

    if (!await _voiceRecorder.hasPermission()) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/accounting_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _voiceRecorder.start(const RecordConfig(), path: path);
    setState(() => _isVoiceRecording = true);
    return null;
  }

  Future<void> _playLastVoiceRecord() async {
    final path = _lastVoicePath;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      AppDialog.error(
        context,
        title: l10n.translate('common.error'),
        message: l10n.translate('accounting.voice_no_record_found'),
      );
      return;
    }

    if (_voicePlayer.state == PlayerState.playing) {
      await _voicePlayer.stop();
      return;
    }

    await _voicePlayer.stop();
    await _voicePlayer.play(DeviceFileSource(path));
  }

  String _mockTranscribeVoice() {
    final sample = <String>[
      'thu tien ban hang 1500000 tu khach le',
      'chi tien van chuyen 350000 thanh toan tien mat',
      'thu doanh thu don hang 2200000 qua chuyen khoan',
    ];
    return sample[DateTime.now().millisecond % sample.length];
  }

  double? _extractAmountFromTranscript(String transcript) {
    final matches = RegExp(r'(\d[\d\.,]*)').allMatches(transcript);
    if (matches.isEmpty) return null;
    final raw = matches.last.group(0) ?? '';
    final normalized = raw.replaceAll(RegExp(r'[\.,]'), '');
    return double.tryParse(normalized);
  }

  String _formatIsoDate(DateTime? date, {String fallback = '-'}) {
    final formatted = DateFormatter.formatIso(date);
    return formatted.isEmpty ? fallback : formatted;
  }

  Future<DateTime?> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    void Function(void Function()) setDialogState,
    void Function(File file) onPicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setDialogState(() => onPicked(File(pickedFile.path)));
    }
  }

  Widget _buildStringDropdownField({
    required String label,
    required String? value,
    required List<ReferenceItem> options,
    required ValueChanged<String?> onChanged,
    bool isExpanded = false,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    AutovalidateMode? autovalidateMode,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: isExpanded,
      focusNode: focusNode,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(labelText: label),
      items: options
          .where((item) => item.label.trim().isNotEmpty)
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.code,
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateSelectorTile({
    required String title,
    required BuildContext dialogCtx,
    required DateTime? value,
    required DateTime initialDate,
    required ValueChanged<DateTime?> onChanged,
    String emptyText = '-',
    bool allowClear = false,
    bool readOnly = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value == null ? emptyText : _formatIsoDate(value)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allowClear && value != null)
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
            ),
          Icon(readOnly ? Icons.lock : Icons.calendar_today),
        ],
      ),
      onTap: readOnly
          ? null
          : () async {
              final picked = await _pickDate(
                context: dialogCtx,
                initialDate: value ?? initialDate,
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
      enabled: !readOnly,
    );
  }

  Widget _buildVoiceAssistControls({
    required AppLocalizations l10n,
    required BuildContext dialogCtx,
    required void Function(VoidCallback) setDialogState,
    required void Function(String transcript) onTranscriptReady,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('accounting.voice_fill_title'),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final transcript = await _toggleVoiceCapture();
                    if (!dialogCtx.mounted) return;
                    if (transcript != null && transcript.trim().isNotEmpty) {
                      onTranscriptReady(transcript);
                    }
                    setDialogState(() {});
                  },
                  icon: Icon(
                    _isVoiceRecording ? Icons.stop_circle : Icons.mic,
                    color: _isVoiceRecording
                        ? AppColors.error
                        : AppColors.secondary,
                  ),
                  label: Text(
                    _isVoiceRecording
                        ? l10n.translate('accounting.voice_stop_record')
                        : l10n.translate('accounting.voice_start_record'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _VoicePlayBtn(
                player: _voicePlayer,
                isDisabled: _lastVoicePath == null,
                onTap: _playLastVoiceRecord,
                label: l10n.translate('accounting.voice_play_back'),
              ),
            ],
          ),
          if ((_lastVoiceTranscript ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.translate('accounting.voice_last_result')}: ${_lastVoiceTranscript ?? ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
  }) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: title,
      message: message,
      confirmText: l10n.translate('common.confirm'),
      cancelText: l10n.translate('common.cancel'),
    );
    return confirmed == true;
  }

  Future<void> _onDeleteRevenue(RevenueEntity item) async {
    if (!_isManualRevenueEntry(item)) {
      _showManualOnlyWarning();
      return;
    }

    if (_isDateInFinalizedPeriod(item.date)) {
      AppSnackBar.warning(
        context,
        _translateWithFallback(
          'accounting.period_finalized_readonly',
          'Kỳ kế toán đã chốt sổ, không thể xóa',
        ),
      );
      return;
    }

    final ok = await _confirmAction(
      title: l10n.translate('accounting.confirm_title'),
      message: l10n.translate('accounting.confirm_delete_revenue'),
    );
    if (!ok) return;

    final allowed = await _checkFeatureAccess(_featureManualRevenue);
    if (!allowed) return;

    if (!mounted) return;
    final locationId = context.read<BusinessContext>().currentBusinessId;
    context.read<RevenueBloc>().add(
      DeleteManualRevenueRequested(
        revenueId: item.id,
        businessLocationId: locationId,
      ),
    );
  }

  Future<void> _onDeleteCost(CostEntity item) async {
    if (!_isManualCostEntry(item)) {
      _showManualOnlyWarning();
      return;
    }

    if (_isDateInFinalizedPeriod(item.date)) {
      AppSnackBar.warning(
        context,
        _translateWithFallback(
          'accounting.period_finalized_readonly',
          'Kỳ kế toán đã chốt sổ, không thể xóa',
        ),
      );
      return;
    }

    final ok = await _confirmAction(
      title: l10n.translate('accounting.confirm_title'),
      message: l10n.translate('accounting.confirm_delete_cost'),
    );
    if (!ok) return;

    if (!mounted) return;
    context.read<CostBloc>().add(DeleteManualCostRequested(item.id));
  }

  void _showSuccess(String message) {
    AppSnackBar.success(context, message);
  }

  String _translateWithFallback(String key, String fallback) {
    final translated = l10n.translate(key);
    return translated == key ? fallback : translated;
  }

  bool _isManualRevenueEntry(RevenueEntity item) {
    final type = item.type.trim().toLowerCase();
    final referenceType = (item.referenceType ?? '').trim().toLowerCase();
    return type == 'manual' || referenceType == 'manual';
  }

  bool _isManualCostEntry(CostEntity item) {
    final type = item.type.trim().toLowerCase();
    final referenceType = (item.referenceType ?? '').trim().toLowerCase();
    if (referenceType == 'manual') {
      return true;
    }
    if (type == 'import') {
      return false;
    }

    if (item.referenceId != null &&
        item.referenceId! > 0 &&
        referenceType.isNotEmpty &&
        referenceType != 'cost') {
      return false;
    }

    return true;
  }

  void _showManualOnlyWarning() {
    AppSnackBar.warning(
      context,
      _translateWithFallback(
        'accounting.manual_only_action',
        'Chỉ có thể sửa hoặc xóa khoản nhập thủ công',
      ),
    );
  }

  Future<bool> _checkFeatureAccess(String featureCode) async {
    try {
      final businessContext = context.read<BusinessContext>();
      final ownerProfileId = businessContext.isOwner
          ? null
          : businessContext.currentOwnerProfileId;

      final allowed = await context
          .read<SubscriptionRepository>()
          .canUseFeatureCode(
            featureCode: featureCode,
            ownerProfileId: ownerProfileId,
          );

      if (!allowed && mounted) {
        AppSnackBar.show(
          context,
          message: l10n.translate('subscription.feature_blocked'),
          type: AppSnackBarType.warning,
          actionLabel: l10n.translate('settings_page.upgrade'),
          onAction: () {
            AppRouter.navigateTo(AppRoutes.subscriptionPlans);
          },
        );
      }

      return allowed;
    } catch (_) {
      // Do not block feature when pre-check fails; backend remains authoritative.
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationId = context.watch<BusinessContext>().currentBusinessId;

    return _buildScaffold(context, locationId);
  }

  Widget _buildScaffold(BuildContext context, String? locationId) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RevenueBloc, RevenueState>(
          listener: (context, state) {
            if (state is RevenueCreated) {
              _suppressNextRevenueError = true;
              _showSuccess(
                l10n.translate('accounting.revenue_created_success'),
              );
            } else if (state is RevenueUpdated) {
              _suppressNextRevenueError = true;
              _showSuccess(
                l10n.translate('accounting.revenue_updated_success'),
              );
            } else if (state is RevenueDeleted) {
              _suppressNextRevenueError = true;
              _showSuccess(
                l10n.translate('accounting.revenue_deleted_success'),
              );
            } else if (state is RevenuesLoaded) {
              _suppressNextRevenueError = false;
            } else if (state is RevenueError) {
              if (_suppressNextRevenueError) {
                _suppressNextRevenueError = false;
                return;
              }
              AppSnackBar.error(context, state.message);
            }
          },
        ),
        BlocListener<CostBloc, CostState>(
          listener: (context, state) {
            if (state is CostOperationSuccess) {
              _showSuccess(l10n.translate('accounting.updated_success'));
              final locationId = context
                  .read<BusinessContext>()
                  .currentBusinessId;
              if (locationId != null) {
                context.read<CostBloc>().add(
                  LoadCostsRequested(businessLocationId: locationId),
                );
              }
            } else if (state is CostOperationFailure) {
              AppSnackBar.error(context, state.message);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: AppColors.textPrimary,
          ),
          title: Text(
            l10n.translate('accounting.title'),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const AppSyncStatusText(),
        ),
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.secondary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.secondary,
                tabs: [
                  Tab(text: l10n.translate('accounting.tab_period')),
                  Tab(text: l10n.translate('accounting.tab_gl')),
                  Tab(text: l10n.translate('accounting.revenue_list')),
                  Tab(text: l10n.translate('accounting.cost_list')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Period: real API via BLoC
                    Builder(
                      builder: (context) {
                        final locationId = context
                            .watch<BusinessContext>()
                            .currentBusinessId;
                        if (locationId == null) {
                          return Center(
                            child: Text(
                              l10n.translate('home.please_select_location'),
                            ),
                          );
                        }
                        return AccountingPeriodTab(locationId: locationId);
                      },
                    ),
                    const AccountingGlTab(),
                    BlocBuilder<RevenueBloc, RevenueState>(
                      builder: (context, revenueState) {
                        // Watch both RevenueBloc and AccountingPeriodBloc for changes
                        context.watch<AccountingPeriodBloc>().state;

                        List<RevenueEntity> revenueEntities = _cachedRevenues;
                        if (revenueState is RevenuesLoaded) {
                          revenueEntities = revenueState.revenues;
                          _cachedRevenues = revenueEntities;
                          _revenuePageNumber = revenueState.pageNumber;
                          _revenuePageSize = revenueState.pageSize;
                          // Sync local loading flag with bloc state after frame
                          if (_isLoadingMoreRevenue !=
                              revenueState.isLoadMore) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(
                                () => _isLoadingMoreRevenue =
                                    revenueState.isLoadMore,
                              );
                            });
                          }
                        }

                        return AccountingCostRevenueTab(
                          mode: AccountingCostRevenueMode.revenue,
                          languageCode: Localizations.localeOf(
                            context,
                          ).languageCode,
                          revenues: revenueEntities,
                          costs: const <CostEntity>[],
                          onAddRevenue: _showCreateRevenueModeDialog,
                          onAddCost: _showCreateCostModeDialog,
                          onEditRevenue: _showEditRevenueDialog,
                          onTapRevenue: _showRevenueDetailDialog,
                          onDeleteRevenue: _onDeleteRevenue,
                          onEditCost: _showEditCostDialog,
                          onTapCost: _showCostDetailDialog,
                          onDeleteCost: _onDeleteCost,
                          canModifyRevenue: _canModifyRevenueEntry,
                          canModifyCost: (item) => false,
                          hasReachedMaxRevenue: revenueState is RevenuesLoaded
                              ? revenueState.hasReachedMax
                              : false,
                          isLoadingMoreRevenue: revenueState is RevenuesLoaded
                              ? revenueState.isLoadMore
                              : false,
                          onLoadMoreRevenue: _loadMoreRevenues,
                        );
                      },
                    ),
                    BlocBuilder<CostBloc, CostState>(
                      builder: (context, costState) {
                        // Watch both CostBloc and AccountingPeriodBloc for changes
                        context.watch<AccountingPeriodBloc>().state;

                        List<CostEntity> costEntities = _cachedCosts;
                        if (costState is CostsLoaded) {
                          costEntities = costState.costs;
                          _cachedCosts = costEntities;
                          _costPageNumber = costState.pageNumber;
                          _costPageSize = costState.pageSize;
                          // Sync local loading flag with bloc state after frame
                          if (_isLoadingMoreCost != costState.isLoadMore) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(
                                () => _isLoadingMoreCost = costState.isLoadMore,
                              );
                            });
                          }
                        }

                        return AccountingCostRevenueTab(
                          mode: AccountingCostRevenueMode.cost,
                          languageCode: Localizations.localeOf(
                            context,
                          ).languageCode,
                          revenues: const <RevenueEntity>[],
                          costs: costEntities,
                          onAddRevenue: _showCreateRevenueModeDialog,
                          onAddCost: _showCreateCostModeDialog,
                          onEditRevenue: _showEditRevenueDialog,
                          onTapRevenue: _showRevenueDetailDialog,
                          onDeleteRevenue: _onDeleteRevenue,
                          onEditCost: _showEditCostDialog,
                          onTapCost: _showCostDetailDialog,
                          onDeleteCost: _onDeleteCost,
                          canModifyRevenue: (item) => false,
                          canModifyCost: _canModifyCostEntry,
                          hasReachedMaxCost: costState is CostsLoaded
                              ? costState.hasReachedMax
                              : false,
                          isLoadingMoreCost: costState is CostsLoaded
                              ? costState.isLoadMore
                              : false,
                          onLoadMoreCost: _loadMoreCosts,
                        );
                      },
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

  List<ReferenceItem> _getMoneyChannelsForDialog() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      return state.references['moneyChannelTypes'] ?? const <ReferenceItem>[];
    }
    return const <ReferenceItem>[];
  }

  List<ReferenceItem> _getCostTypesForDialog() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      return (state.references['costTypes'] ?? const <ReferenceItem>[])
          .where((c) => c.code.toLowerCase() != 'import')
          .toSet()
          .toList();
    }
    return const <ReferenceItem>[];
  }

  Future<void> _showCreateRevenueModeDialog() async {
    final selected = await AppBottomSheet.showList<_EntryCreateMode>(
      context,
      items: [
        AppBottomSheetItem<_EntryCreateMode>(
          icon: Icons.edit_note_outlined,
          title: l10n.translate('accounting.create_mode_manual'),
          subtitle: l10n.translate('accounting.create_mode_manual_subtitle'),
          value: _EntryCreateMode.manual,
        ),
        AppBottomSheetItem<_EntryCreateMode>(
          icon: Icons.auto_awesome_outlined,
          title: l10n.translate('accounting.create_mode_ai_draft'),
          subtitle: l10n.translate('accounting.create_mode_ai_draft_subtitle'),
          value: _EntryCreateMode.aiDraft,
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == _EntryCreateMode.manual) {
      await _showAddRevenueDialog();
      return;
    }

    final allowed = await _checkFeatureAccess(_featureAi);
    if (!allowed || !mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AIDraftRevenueDialog(
          voiceItems: const [],
          getMoneyChannels: _getMoneyChannelsForDialog,
          parentContext: context,
        ),
      ),
    );
  }

  Future<void> _showCreateCostModeDialog() async {
    final selected = await AppBottomSheet.showList<_EntryCreateMode>(
      context,
      items: [
        AppBottomSheetItem<_EntryCreateMode>(
          icon: Icons.edit_note_outlined,
          title: l10n.translate('accounting.create_mode_manual'),
          subtitle: l10n.translate('accounting.create_mode_manual_subtitle'),
          value: _EntryCreateMode.manual,
        ),
        AppBottomSheetItem<_EntryCreateMode>(
          icon: Icons.auto_awesome_outlined,
          title: l10n.translate('accounting.create_mode_ai_draft'),
          subtitle: l10n.translate('accounting.create_mode_ai_draft_subtitle'),
          value: _EntryCreateMode.aiDraft,
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == _EntryCreateMode.manual) {
      await _showAddCostDialog();
      return;
    }

    final allowed = await _checkFeatureAccess(_featureAi);
    if (!allowed || !mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AIDraftCostDialog(
          voiceItems: const [],
          getMoneyChannels: _getMoneyChannelsForDialog,
          getCostTypes: _getCostTypesForDialog,
          parentContext: context,
        ),
      ),
    );
  }

  Future<void> _showAddRevenueDialog() async {
    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final documentNumberController = TextEditingController();
    final referenceOrderIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final amountFocusNode = FocusNode();
    final descriptionFocusNode = FocusNode();
    final referenceOrderFocusNode = FocusNode();
    final moneyChannelFocusNode = FocusNode();
    final businessTypeFocusNode = FocusNode();
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDocumentDate;
    String? selectedMoneyChannel;
    String? selectedBusinessTypeId;
    File? selectedImage;
    List<BusinessTypeDto> businessTypes = [];

    try {
      final result = await context
          .read<ProductBloc>()
          .repository
          .getBusinessTypes();
      businessTypes = List<BusinessTypeDto>.from(result);
    } catch (_) {
      businessTypes = [];
    }

    if (!mounted) return;

    List<ReferenceItem> getMoneyChannels() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return state.references['moneyChannelTypes'] ?? const <ReferenceItem>[];
      }
      return const <ReferenceItem>[];
    }

    bool isSubmitting = false;
    bool didSubmit = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.add_revenue')),
          content: Form(
            key: formKey,
            autovalidateMode: didSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    label: l10n.translate('accounting.revenue_amount'),
                    focusNode: amountFocusNode,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final amount = (CurrencyFormatter.parse(value ?? '') ?? 0)
                          .toDouble();
                      if (amount <= 0) {
                        return _translateWithFallback(
                          'accounting.amount_required',
                          'Vui lòng nhập số tiền hợp lệ',
                        );
                      }
                      return null;
                    },
                    onSubmitted: (_) => FocusScope.of(
                      dialogCtx,
                    ).requestFocus(descriptionFocusNode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: descriptionController,
                    label: l10n.translate('accounting.revenue_description'),
                    focusNode: descriptionFocusNode,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _translateWithFallback(
                          'accounting.description_required',
                          'Vui lòng nhập mô tả',
                        );
                      }
                      return null;
                    },
                    onSubmitted: (_) => FocusScope.of(
                      dialogCtx,
                    ).requestFocus(moneyChannelFocusNode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStringDropdownField(
                    label: l10n.translate('accounting.channel'),
                    value: selectedMoneyChannel,
                    options: getMoneyChannels(),
                    focusNode: moneyChannelFocusNode,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return l10n.translate(
                          'accounting.money_channel_required',
                        );
                      }
                      return null;
                    },
                    autovalidateMode: didSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    onChanged: (value) {
                      setDialogState(() => selectedMoneyChannel = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedBusinessTypeId,
                    focusNode: businessTypeFocusNode,
                    autovalidateMode: didSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: InputDecoration(
                      labelText: l10n.translate(
                        'accounting.revenue_business_type',
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _translateWithFallback(
                          'accounting.business_type_required',
                          'Vui lòng chọn loại hình kinh doanh',
                        );
                      }
                      return null;
                    },
                    items: businessTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type.businessTypeId,
                            child: Text(
                              type.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBusinessTypeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: referenceOrderIdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    label: l10n.translate('accounting.reference_order_id'),
                    hintText: l10n.translate(
                      'accounting.reference_order_id_hint',
                    ),
                    focusNode: referenceOrderFocusNode,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final raw = (value ?? '').trim();
                      if (raw.isEmpty) return null;
                      if (int.tryParse(raw) == null) {
                        return _translateWithFallback(
                          'accounting.reference_order_id_invalid',
                          'Mã đơn hàng không hợp lệ',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDateSelectorTile(
                    title: l10n.translate('accounting.revenue_date'),
                    dialogCtx: dialogCtx,
                    value: selectedDate,
                    initialDate: selectedDate,
                    readOnly: true,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedDate = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: documentNumberController,
                    label: l10n.translate('accounting.document_number'),
                    hintText: l10n.translate('accounting.document_number_hint'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Image upload section
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: Text(l10n.translate('accounting.select_image')),
                        onPressed: () => _pickImage(
                          ImageSource.gallery,
                          setDialogState,
                          (file) => selectedImage = file,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.translate('accounting.take_photo')),
                        onPressed: () => _pickImage(
                          ImageSource.camera,
                          setDialogState,
                          (file) => selectedImage = file,
                        ),
                      ),
                    ],
                  ),
                  if (selectedImage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Image.file(
                        selectedImage!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => didSubmit = true);

                      final isValid = formKey.currentState?.validate() ?? false;
                      if (!isValid) {
                        final amount =
                            (CurrencyFormatter.parse(amountController.text) ??
                                    0)
                                .toDouble();
                        if (amount <= 0) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(amountFocusNode);
                          return;
                        }
                        if (descriptionController.text.trim().isEmpty) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(descriptionFocusNode);
                          return;
                        }
                        if ((selectedMoneyChannel ?? '').trim().isEmpty) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(moneyChannelFocusNode);
                          return;
                        }
                        if ((selectedBusinessTypeId ?? '').trim().isEmpty) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(businessTypeFocusNode);
                          return;
                        }
                        FocusScope.of(
                          dialogCtx,
                        ).requestFocus(referenceOrderFocusNode);
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final amount =
                          (CurrencyFormatter.parse(amountController.text) ?? 0)
                              .toDouble();

                      final referenceOrderRaw = referenceOrderIdController.text
                          .trim();
                      final referenceOrderId = referenceOrderRaw.isEmpty
                          ? null
                          : int.tryParse(referenceOrderRaw);

                      // Document number duplicate check
                      final docNum = documentNumberController.text.trim();
                      if (docNum.isNotEmpty) {
                        final canProceed = await checkDocumentNumberAndConfirm(
                          context,
                          documentNumber: docNum,
                        );
                        if (!canProceed) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          return;
                        }
                        if (!mounted || !dialogCtx.mounted) return;
                      }

                      final ok = await _confirmAction(
                        title: l10n.translate('accounting.confirm_title'),
                        message: l10n.translate(
                          'accounting.confirm_create_revenue',
                        ),
                      );
                      if (!ok || !context.mounted) {
                        if (dialogCtx.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                        return;
                      }

                      final allowed = await _checkFeatureAccess(
                        _featureManualRevenue,
                      );
                      if (!allowed) {
                        if (dialogCtx.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                        return;
                      }

                      if (!mounted) return;
                      if (!dialogCtx.mounted) {
                        return;
                      }

                      // Use outer page context — dialog ctx has no Providers
                      final locationId = context
                          .read<BusinessContext>()
                          .currentBusinessId;

                      try {
                        await context
                            .read<RevenueBloc>()
                            .repository
                            .createManualRevenue({
                              'businessLocationId':
                                  int.tryParse(locationId ?? '') ?? 0,
                              'amount': amount,
                              'revenueDate': DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate),
                              if (selectedDocumentDate != null)
                                'documentDate': DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedDocumentDate!),
                              'description': descriptionController.text.trim(),
                              'moneyChannel': selectedMoneyChannel,
                              if (documentNumberController.text
                                  .trim()
                                  .isNotEmpty)
                                'documentNumber': documentNumberController.text
                                    .trim(),
                              if ((selectedBusinessTypeId ?? '').isNotEmpty)
                                'businessTypeId': selectedBusinessTypeId,
                              if (referenceOrderId != null)
                                'referenceType': 'order',
                              if (referenceOrderId != null)
                                'referenceId': referenceOrderId,
                            }, image: selectedImage);
                        if (!mounted || !dialogCtx.mounted) return;
                        Navigator.of(dialogCtx).pop();
                        _showSuccess(
                          l10n.translate('accounting.revenue_created_success'),
                        );
                        if (locationId != null) {
                          context.read<RevenueBloc>().add(
                            LoadRevenuesRequested(
                              businessLocationId: locationId,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!dialogCtx.mounted) return;
                        await AppDialog.error(
                          dialogCtx,
                          title: l10n.translate('common.error'),
                          message: ApiErrorMessageParser.parse(e),
                        );
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );

    amountFocusNode.dispose();
    descriptionFocusNode.dispose();
    referenceOrderFocusNode.dispose();
    moneyChannelFocusNode.dispose();
    businessTypeFocusNode.dispose();
    amountController.dispose();
    descriptionController.dispose();
    referenceOrderIdController.dispose();
    documentNumberController.dispose();
  }

  Future<OrderEntity?> _loadLinkedOrder(RevenueEntity revenue) async {
    final refId = revenue.referenceId;
    if (refId == null || refId <= 0) return null;

    if (!_shouldOpenOrderFromRevenue(revenue)) {
      return null;
    }

    try {
      return await context.read<OrderBloc>().repository.getOrder(
        refId.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showAddCostDialog() async {
    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final documentNumberController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final amountFocusNode = FocusNode();
    final descriptionFocusNode = FocusNode();
    final costTypeFocusNode = FocusNode();
    final paymentMethodFocusNode = FocusNode();
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDocumentDate;
    String? selectedCostType;
    String? selectedPaymentMethod;

    List<ReferenceItem> getCostTypes() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['costTypes'] ?? const <ReferenceItem>[])
            .toSet()
            .toList();
      }
      return const <ReferenceItem>[];
    }

    List<ReferenceItem> getPaymentMethods() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['paymentMethods'] ?? const <ReferenceItem>[])
            .toSet()
            .toList();
      }
      return const <ReferenceItem>[];
    }

    bool isSubmitting = false;
    bool didSubmit = false;
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.add_cost')),
          content: Form(
            key: formKey,
            autovalidateMode: didSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: descriptionController,
                    label: l10n.translate('accounting.description'),
                    focusNode: descriptionFocusNode,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _translateWithFallback(
                          'accounting.description_required',
                          'Vui lòng nhập mô tả',
                        );
                      }
                      return null;
                    },
                    onSubmitted: (_) =>
                        FocusScope.of(dialogCtx).requestFocus(amountFocusNode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    label: l10n.translate('accounting.amount'),
                    focusNode: amountFocusNode,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final amount = (CurrencyFormatter.parse(value ?? '') ?? 0)
                          .toDouble();
                      if (amount <= 0) {
                        return _translateWithFallback(
                          'accounting.amount_required',
                          'Vui lòng nhập số tiền hợp lệ',
                        );
                      }
                      return null;
                    },
                    onSubmitted: (_) => FocusScope.of(
                      dialogCtx,
                    ).requestFocus(costTypeFocusNode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStringDropdownField(
                    label: l10n.translate('accounting.ai_cost_type'),
                    value: selectedCostType,
                    focusNode: costTypeFocusNode,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _translateWithFallback(
                          'accounting.cost_type_required',
                          'Vui lòng chọn loại chi phí',
                        );
                      }
                      return null;
                    },
                    autovalidateMode: didSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    options: getCostTypes()
                        .where((c) => c.code.toLowerCase() != 'import')
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedCostType = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStringDropdownField(
                    label: l10n.translate('accounting.payment_method'),
                    value: selectedPaymentMethod,
                    focusNode: paymentMethodFocusNode,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _translateWithFallback(
                          'accounting.payment_method_required',
                          'Vui lòng chọn phương thức thanh toán',
                        );
                      }
                      return null;
                    },
                    autovalidateMode: didSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    options: getPaymentMethods(),
                    onChanged: (value) =>
                        setDialogState(() => selectedPaymentMethod = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDateSelectorTile(
                    title: l10n.translate('accounting.cost_date'),
                    dialogCtx: dialogCtx,
                    value: selectedDate,
                    initialDate: selectedDate,
                    readOnly: true,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedDate = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: documentNumberController,
                    label: l10n.translate('accounting.document_number'),
                    hintText: l10n.translate('accounting.document_number_hint'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Image upload section
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: Text(l10n.translate('accounting.select_image')),
                        onPressed: () => _pickImage(
                          ImageSource.gallery,
                          setDialogState,
                          (file) => selectedImage = file,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.translate('accounting.take_photo')),
                        onPressed: () => _pickImage(
                          ImageSource.camera,
                          setDialogState,
                          (file) => selectedImage = file,
                        ),
                      ),
                    ],
                  ),
                  if (selectedImage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Image.file(
                        selectedImage!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => didSubmit = true);

                      final isValid = formKey.currentState?.validate() ?? false;
                      if (!isValid) {
                        if (descriptionController.text.trim().isEmpty) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(descriptionFocusNode);
                          return;
                        }

                        final amount =
                            (CurrencyFormatter.parse(amountController.text) ??
                                    0)
                                .toDouble();
                        if (amount <= 0) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(amountFocusNode);
                          return;
                        }

                        if ((selectedCostType ?? '').trim().isEmpty) {
                          FocusScope.of(
                            dialogCtx,
                          ).requestFocus(costTypeFocusNode);
                          return;
                        }

                        FocusScope.of(
                          dialogCtx,
                        ).requestFocus(paymentMethodFocusNode);
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final amount =
                          (CurrencyFormatter.parse(amountController.text) ?? 0)
                              .toDouble();

                      // Document number duplicate check
                      final docNum = documentNumberController.text.trim();
                      if (docNum.isNotEmpty) {
                        final canProceed = await checkDocumentNumberAndConfirm(
                          context,
                          documentNumber: docNum,
                        );
                        if (!canProceed) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          return;
                        }
                        if (!mounted || !dialogCtx.mounted) return;
                      }

                      final locationId = context
                          .read<BusinessContext>()
                          .currentBusinessId;
                      try {
                        await context
                            .read<CostBloc>()
                            .repository
                            .createManualCost({
                              'businessLocationId':
                                  int.tryParse(locationId ?? '') ?? 0,
                              'amount': amount,
                              'costDate': DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate),
                              if (selectedDocumentDate != null)
                                'documentDate': DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedDocumentDate!),
                              'description': descriptionController.text.trim(),
                              'costType': selectedCostType,
                              'paymentMethod': selectedPaymentMethod,
                              if (documentNumberController.text
                                  .trim()
                                  .isNotEmpty)
                                'documentNumber': documentNumberController.text
                                    .trim(),
                            }, image: selectedImage);
                        if (!mounted || !dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        _showSuccess(
                          l10n.translate('accounting.updated_success'),
                        );
                        if (locationId != null) {
                          context.read<CostBloc>().add(
                            LoadCostsRequested(businessLocationId: locationId),
                          );
                        }
                      } catch (e) {
                        if (!dialogCtx.mounted) return;
                        await AppDialog.error(
                          dialogCtx,
                          title: l10n.translate('common.error'),
                          message: ApiErrorMessageParser.parse(e),
                        );
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );

    amountFocusNode.dispose();
    descriptionFocusNode.dispose();
    costTypeFocusNode.dispose();
    paymentMethodFocusNode.dispose();
    amountController.dispose();
    descriptionController.dispose();
    documentNumberController.dispose();
  }

  Future<void> _showEditCostDialog(CostEntity item) async {
    if (!_isManualCostEntry(item)) {
      _showManualOnlyWarning();
      return;
    }

    // Check if date falls in finalized period
    if (_isDateInFinalizedPeriod(item.date)) {
      AppSnackBar.warning(
        context,
        _translateWithFallback(
          'accounting.period_finalized_readonly',
          'Kỳ kế toán đã chốt sổ, không thể chỉnh sửa',
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController(
      text: CurrencyFormatter.formatNumber(item.amount),
    );
    final descriptionController = TextEditingController(text: item.description);
    final documentNumberController = TextEditingController(
      text: item.documentNumber ?? '',
    );
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDocumentDate = item.documentDate;
    String? selectedCostType = item.type;
    String? selectedPaymentMethod = item.paymentMethod;

    List<ReferenceItem> getCostTypes() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['costTypes'] ?? const <ReferenceItem>[])
            .toSet()
            .toList();
      }
      return const <ReferenceItem>[];
    }

    List<ReferenceItem> getPaymentMethods() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['paymentMethods'] ?? const <ReferenceItem>[])
            .toSet()
            .toList();
      }
      return const <ReferenceItem>[];
    }

    final costTypeOptions = getCostTypes()
        .where((c) => c.code.toLowerCase() != 'import')
        .toList();
    if (selectedCostType != null &&
        selectedCostType.isNotEmpty &&
        !costTypeOptions.any((c) => c.code == selectedCostType)) {
      selectedCostType = null;
    }

    final paymentOptions = getPaymentMethods();
    if (selectedPaymentMethod != null &&
        selectedPaymentMethod.isNotEmpty &&
        !paymentOptions.any((p) => p.code == selectedPaymentMethod)) {
      selectedPaymentMethod = null;
    }

    bool isSubmitting = false;
    bool removeImage = false;
    File? selectedImage;
    // We don't initialize selectedImage from item.imagePath if it's a network URL
    // since File() won't work on URLs. We handle network display separately.

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.edit_cost')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: descriptionController,
                  label: l10n.translate('accounting.description'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  label: l10n.translate('accounting.amount'),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildStringDropdownField(
                  label: l10n.translate('accounting.ai_cost_type'),
                  value: selectedCostType,
                  options: costTypeOptions.toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCostType = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildStringDropdownField(
                  label: l10n.translate('accounting.payment_method'),
                  value: selectedPaymentMethod,
                  options: paymentOptions.toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedPaymentMethod = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildDateSelectorTile(
                  title: l10n.translate('accounting.cost_date'),
                  dialogCtx: dialogCtx,
                  value: selectedDate,
                  initialDate: selectedDate,
                  readOnly: true,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDate = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: documentNumberController,
                  label: l10n.translate('accounting.document_number'),
                  hintText: l10n.translate('accounting.document_number_hint'),
                ),
                const SizedBox(height: AppSpacing.md),
                // Image upload section
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                              l10n.translate('accounting.select_image'),
                            ),
                            onPressed: () => _pickImage(
                              ImageSource.gallery,
                              setDialogState,
                              (file) {
                                selectedImage = file;
                                removeImage = false;
                              },
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              l10n.translate('accounting.take_photo'),
                            ),
                            onPressed: () => _pickImage(
                              ImageSource.camera,
                              setDialogState,
                              (file) {
                                selectedImage = file;
                                removeImage = false;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedImage != null ||
                        ((item.imagePath?.isNotEmpty == true ||
                                item.documentUrl?.isNotEmpty == true) &&
                            !removeImage))
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => setDialogState(() {
                          selectedImage = null;
                          removeImage = true;
                        }),
                      ),
                  ],
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Image.file(
                      selectedImage!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ] else if ((item.imagePath?.isNotEmpty == true ||
                        item.documentUrl?.isNotEmpty == true) &&
                    !removeImage) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Builder(
                      builder: (context) {
                        final imageSource = _resolveImageSource(
                          item.documentUrl ?? item.imagePath,
                        );
                        if (imageSource == null) {
                          return const SizedBox(
                            height: 120,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }
                        return _buildDetailImage(imageSource, height: 120);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final amount =
                          (CurrencyFormatter.parse(amountController.text) ?? 0)
                              .toDouble();
                      if (descriptionController.text.trim().isEmpty) {
                        await AppDialog.show(
                          dialogCtx,
                          title: l10n.translate('common.warning'),
                          message: _translateWithFallback(
                            'accounting.description_required',
                            'Vui lòng nhập mô tả',
                          ),
                          type: AppDialogType.warning,
                        );
                        setDialogState(() => isSubmitting = false);
                        return;
                      }

                      if (amount <= 0) {
                        await AppDialog.show(
                          dialogCtx,
                          title: l10n.translate('common.warning'),
                          message: _translateWithFallback(
                            'accounting.amount_required',
                            'Vui lòng nhập số tiền hợp lệ',
                          ),
                          type: AppDialogType.warning,
                        );
                        setDialogState(() => isSubmitting = false);
                        return;
                      }

                      if ((selectedCostType ?? '').trim().isEmpty) {
                        await AppDialog.show(
                          dialogCtx,
                          title: l10n.translate('common.warning'),
                          message: _translateWithFallback(
                            'accounting.cost_type_required',
                            'Vui lòng chọn loại chi phí',
                          ),
                          type: AppDialogType.warning,
                        );
                        setDialogState(() => isSubmitting = false);
                        return;
                      }

                      if ((selectedPaymentMethod ?? '').trim().isEmpty) {
                        await AppDialog.show(
                          dialogCtx,
                          title: l10n.translate('common.warning'),
                          message: _translateWithFallback(
                            'accounting.payment_method_required',
                            'Vui lòng chọn phương thức thanh toán',
                          ),
                          type: AppDialogType.warning,
                        );
                        setDialogState(() => isSubmitting = false);
                        return;
                      }

                      // Document number duplicate check
                      final docNum = documentNumberController.text.trim();
                      if (docNum.isNotEmpty) {
                        final canProceed = await checkDocumentNumberAndConfirm(
                          context,
                          documentNumber: docNum,
                          excludeCostId: item.id,
                        );
                        if (!canProceed) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          return;
                        }
                      }

                      if (!mounted || !dialogCtx.mounted) {
                        return;
                      }

                      // Use outer context to read BLoC safely
                      context.read<CostBloc>().add(
                        UpdateManualCostRequested(
                          costId: item.id,
                          idempotencyKey: const Uuid().v4(),
                          body: {
                            'amount': amount,
                            'costDate': DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDate),
                            'documentDate': selectedDocumentDate == null
                                ? null
                                : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(selectedDocumentDate!),
                            'description': descriptionController.text.trim(),
                            'costType': selectedCostType ?? item.type,
                            'paymentMethod':
                                selectedPaymentMethod ?? item.paymentMethod,
                            if (documentNumberController.text.trim().isNotEmpty)
                              'documentNumber': documentNumberController.text
                                  .trim(),
                            'removeDocument': removeImage,
                          },
                          image: selectedImage,
                        ),
                      );
                      Navigator.of(dialogCtx).pop();
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );

    amountController.dispose();
    descriptionController.dispose();
    documentNumberController.dispose();
  }

  Future<void> _showRevenueDetailDialog(RevenueEntity revenue) async {
    final locationId = context.read<BusinessContext>().currentBusinessId ?? '';
    final languageCode = Localizations.localeOf(context).languageCode;
    final referenceLabel = AccountingReferenceDisplay.displayReference(
      referenceType: revenue.referenceType,
      referenceId: revenue.referenceId,
      referenceCode: revenue.referenceCode ?? revenue.revenueCode,
      languageCode: languageCode,
      fallback: '-',
    );
    final displayDescription =
        AccountingReferenceDisplay.displayDescriptionValue(
          description: revenue.description,
          referenceType: revenue.referenceType,
          referenceId: revenue.referenceId,
          referenceCode: revenue.referenceCode ?? revenue.revenueCode,
          languageCode: languageCode,
        );

    final shouldOpenImport = _shouldOpenImportFromRevenue(revenue);
    int refId = _resolveReferenceId(revenue.referenceId, revenue.referenceCode);
    if (shouldOpenImport) {
      if (refId <= 0) {
        refId = await _resolveImportIdByReferenceCode(revenue.referenceCode);
        if (!mounted) return;
      }
      if (refId > 0) {
        AppRouter.navigateTo(
          AppRoutes.stockImport,
          arguments: {'locationId': locationId, 'importId': refId},
        );
        return;
      }
    }

    if (refId > 0) {
      if (_shouldOpenOrderFromRevenue(revenue)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: refId.toString()),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    AppDialog.show(
      context,
      title: AccountingReferenceDisplay.displayReference(
        referenceType: 'revenue',
        referenceId: revenue.id,
        languageCode: languageCode,
        fallback: 'REV-${revenue.id}',
      ),
      confirmText: l10n.translate('common.close'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((revenue.imagePath ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      final imageSource = _resolveImageSource(
                        revenue.imagePath,
                      );
                      if (imageSource == null) {
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: _buildDetailImage(imageSource),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Builder(
                        builder: (_) {
                          final imageSource = _resolveImageSource(
                            revenue.imagePath,
                          );
                          if (imageSource == null) {
                            return const SizedBox(
                              height: 120,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }

                          return _buildDetailImage(imageSource, height: 120);
                        },
                      ),
                    ),
                  ),
                ),
              Text(
                '${l10n.translate('accounting.amount')}: ${CurrencyFormatter.formatVND(revenue.amount)}',
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.translate('accounting.description')}: $displayDescription',
              ),
              const SizedBox(height: 6),
              if ((revenue.documentNumber ?? '').trim().isNotEmpty) ...[
                Text(
                  '${l10n.translate('accounting.document_number')}: ${revenue.documentNumber!.trim()}',
                ),
                const SizedBox(height: 6),
              ],
              Text(
                '${l10n.translate('accounting.channel')}: ${revenue.moneyChannel ?? '-'}',
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.translate('accounting.revenue_business_type')}: ${revenue.businessTypeName ?? '-'}',
              ),
              const SizedBox(height: 6),
              Text(
                l10n.translate(
                  'accounting.reference_label',
                  params: {'value': referenceLabel},
                ),
              ),
              const SizedBox(height: 12),
              if ((revenue.referenceType ?? '').toLowerCase() == 'order' &&
                  (revenue.referenceId ?? 0) > 0) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('accounting.linked_order_detail'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<OrderEntity?>(
                  future: _loadLinkedOrder(revenue),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final order = snapshot.data;
                    if (order == null) {
                      return Text(
                        l10n.translate('accounting.order_detail_unavailable'),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.translate('order.detail_order_id')}: ${order.id}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.translate('order.detail_status')}: ${order.statusLabel ?? (() {
                                final refState = context.read<ReferenceBloc>().state;
                                if (refState is ReferenceLoaded) {
                                  final orderStatuses = refState.references['orderStatuses'] ?? <ReferenceItem>[];
                                  return orderStatuses.getLabelByCode(order.status);
                                }
                                return order.status;
                              })()}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.translate('order.detail_total')}: ${CurrencyFormatter.formatVND(order.totalAmount)}',
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${item.productName} x${item.quantity} - ${CurrencyFormatter.formatVND(item.price)}',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCostDetailDialog(CostEntity cost) async {
    final locationId = context.read<BusinessContext>().currentBusinessId ?? '';
    final languageCode = Localizations.localeOf(context).languageCode;
    final referenceLabel = AccountingReferenceDisplay.displayReference(
      referenceType: cost.referenceType,
      referenceId: cost.referenceId,
      referenceCode: cost.referenceCode ?? cost.costCode,
      languageCode: languageCode,
      fallback: '-',
    );
    final displayDescription =
        AccountingReferenceDisplay.displayDescriptionValue(
          description: cost.description,
          referenceType: cost.referenceType,
          referenceId: cost.referenceId,
          referenceCode: cost.referenceCode ?? cost.costCode,
          languageCode: languageCode,
        );

    final shouldOpenImport = _shouldOpenImportFromCost(cost);
    int refId = _resolveReferenceId(cost.referenceId, cost.referenceCode);
    if (shouldOpenImport) {
      if (refId <= 0) {
        refId = await _resolveImportIdByReferenceCode(cost.referenceCode);
        if (!mounted) return;
      }
      if (refId > 0) {
        AppRouter.navigateTo(
          AppRoutes.stockImport,
          arguments: {'locationId': locationId, 'importId': refId},
        );
        return;
      }
    }

    if (refId > 0) {
      if (_shouldOpenOrderFromCost(cost)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: refId.toString()),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    AppDialog.show(
      context,
      title: AccountingReferenceDisplay.displayReference(
        referenceType: 'cost',
        referenceId: cost.id,
        languageCode: languageCode,
        fallback: 'COST-${cost.id}',
      ),
      confirmText: l10n.translate('common.close'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((cost.documentUrl ?? cost.imagePath ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      final imageSource = _resolveImageSource(
                        cost.documentUrl ?? cost.imagePath,
                      );
                      if (imageSource == null) {
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: _buildDetailImage(imageSource),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Builder(
                        builder: (_) {
                          final imageSource = _resolveImageSource(
                            cost.documentUrl ?? cost.imagePath,
                          );
                          if (imageSource == null) {
                            return const SizedBox(
                              height: 120,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }
                          return _buildDetailImage(imageSource, height: 120);
                        },
                      ),
                    ),
                  ),
                ),
              Text(
                '${l10n.translate('accounting.amount')}: ${CurrencyFormatter.formatVND(cost.amount)}',
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.translate('accounting.description')}: $displayDescription',
              ),
              const SizedBox(height: 6),
              if ((cost.documentNumber ?? '').trim().isNotEmpty) ...[
                Text(
                  '${l10n.translate('accounting.document_number')}: ${cost.documentNumber!.trim()}',
                ),
                const SizedBox(height: 6),
              ],
              Text(
                '${l10n.translate('accounting.channel')}: ${cost.paymentMethod ?? '-'}',
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.translate('accounting.cost_date')}: ${_formatIsoDate(cost.date)}',
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.translate('accounting.ai_cost_type')}: ${cost.type}',
              ),
              const SizedBox(height: 6),
              Text(
                l10n.translate(
                  'accounting.reference_label',
                  params: {'value': referenceLabel},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeReferenceType(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    return raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _isOrderReference(String? referenceType, String? referenceCode) {
    final normalizedType = _normalizeReferenceType(referenceType);
    final normalizedCode = (referenceCode ?? '').trim().toLowerCase();
    return normalizedType.contains('order') ||
        normalizedCode.startsWith('ord') ||
        normalizedCode.startsWith('order');
  }

  bool _isImportReference(String? referenceType, String? referenceCode) {
    final normalizedType = _normalizeReferenceType(referenceType);
    final normalizedCode = (referenceCode ?? '').trim().toLowerCase();
    return normalizedType.contains('import') ||
        normalizedType.contains('inventory') ||
        normalizedType.contains('stockin') ||
        normalizedCode.startsWith('imp') ||
        normalizedCode.contains('pnk') ||
        normalizedCode.startsWith('pnk') ||
        normalizedCode.startsWith('import');
  }

  bool _shouldOpenOrderFromRevenue(RevenueEntity revenue) {
    final normalizedType = _normalizeReferenceType(revenue.type);
    return _isOrderReference(revenue.referenceType, revenue.referenceCode) ||
        normalizedType.contains('sale') ||
        normalizedType.contains('order');
  }

  bool _shouldOpenImportFromRevenue(RevenueEntity revenue) {
    final normalizedType = _normalizeReferenceType(revenue.type);
    return _isImportReference(revenue.referenceType, revenue.referenceCode) ||
        normalizedType.contains('import') ||
        normalizedType.contains('inventory');
  }

  bool _shouldOpenOrderFromCost(CostEntity cost) {
    final normalizedType = _normalizeReferenceType(cost.type);
    return _isOrderReference(cost.referenceType, cost.referenceCode) ||
        normalizedType.contains('order');
  }

  bool _shouldOpenImportFromCost(CostEntity cost) {
    final normalizedType = _normalizeReferenceType(cost.type);
    return _isImportReference(cost.referenceType, cost.referenceCode) ||
        normalizedType.contains('import') ||
        normalizedType.contains('inventory');
  }

  int _resolveReferenceId(int? referenceId, String? referenceCode) {
    if (referenceId != null && referenceId > 0) {
      return referenceId;
    }

    final code = (referenceCode ?? '').trim();
    if (code.isEmpty) {
      return 0;
    }

    if (RegExp(r'^\d+$').hasMatch(code)) {
      return int.tryParse(code) ?? 0;
    }

    final pnkMatch = RegExp(
      r'pnk[\-_/:#]*\d+[\-_/:#]*(\d+)$',
      caseSensitive: false,
    ).firstMatch(code);
    if (pnkMatch != null) {
      return int.tryParse(pnkMatch.group(1) ?? '') ?? 0;
    }

    // Only infer id from explicit id-like prefixes to avoid guessing from
    // document serials such as PNK-2026-007.
    final match =
        RegExp(
          r'(?:import|imp|order|ord|id)[^0-9]*(\d+)$',
          caseSensitive: false,
        ).firstMatch(code) ??
        RegExp(
          r'\b(id|importid|orderid)\s*[:=#-]\s*(\d+)\b',
          caseSensitive: false,
        ).firstMatch(code);
    if (match == null) {
      return 0;
    }

    final idGroup = match.groupCount >= 2 ? match.group(2) : match.group(1);
    return int.tryParse(idGroup ?? '') ?? 0;
  }

  Future<int> _resolveImportIdByReferenceCode(String? referenceCode) async {
    final code = (referenceCode ?? '').trim();
    if (code.isEmpty) {
      return 0;
    }

    final locationIdRaw = context.read<BusinessContext>().currentBusinessId;
    final locationId = int.tryParse(locationIdRaw ?? '');
    if (locationId == null || locationId <= 0) {
      return 0;
    }

    final repository = context.read<ImportRepository>();

    String normalize(String value) {
      return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    try {
      final data = await repository.getImports(
        businessLocationId: locationId,
        pageNumber: 1,
        pageSize: 200,
      );

      final items = (data['items'] as List<dynamic>? ?? const []);
      final normalizedCode = normalize(code);
      for (final raw in items) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }

        final importCode = (raw['importCode'] ?? raw['ImportCode'] ?? '')
            .toString();
        if (importCode.trim().isEmpty) {
          continue;
        }

        if (normalize(importCode) == normalizedCode) {
          final importIdRaw = raw['importId'] ?? raw['ImportId'];
          if (importIdRaw is int && importIdRaw > 0) {
            return importIdRaw;
          }
          if (importIdRaw is num && importIdRaw > 0) {
            return importIdRaw.toInt();
          }
          final parsed = int.tryParse(importIdRaw?.toString() ?? '');
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }
      }
    } catch (_) {
      return 0;
    }

    return 0;
  }

  _ImageSource? _resolveImageSource(String? rawPath) {
    final value = (rawPath ?? '').trim();
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _ImageSource.network(Uri.parse(value).toString());
    }

    if (value.startsWith('file://')) {
      final localPath = Uri.tryParse(value)?.toFilePath() ?? value;
      return _ImageSource.file(localPath);
    }

    if (_looksLikeLocalFilePath(value)) {
      return _ImageSource.file(value);
    }

    final normalizedBase = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final slashNormalized = value.replaceAll('\\', '/');
    final normalizedPath = slashNormalized.startsWith('/')
        ? slashNormalized
        : '/$slashNormalized';
    return _ImageSource.network(
      Uri.parse('$normalizedBase$normalizedPath').toString(),
    );
  }

  Widget _buildDetailImage(_ImageSource imageSource, {double? height}) {
    if (imageSource.isNetwork) {
      final resolvedImageUrl =
          Uri.tryParse(imageSource.value)?.toString() ?? imageSource.value;

      return CachedNetworkImage(
        imageUrl: resolvedImageUrl,
        height: height,
        fit: height == null ? BoxFit.contain : BoxFit.cover,
        placeholder: (context, url) => SizedBox(
          height: height ?? 220,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => SizedBox(
          height: height ?? 220,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    return Image.file(
      File(imageSource.value),
      height: height,
      fit: height == null ? BoxFit.contain : BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height ?? 220,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }

  bool _looksLikeLocalFilePath(String path) {
    if (path.startsWith('content://')) {
      return true;
    }

    final hasWindowsDrivePrefix = RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
    if (hasWindowsDrivePrefix) {
      return true;
    }

    if (path.startsWith('/storage/') ||
        path.startsWith('/data/') ||
        path.startsWith('/var/')) {
      return true;
    }

    return File(path).existsSync();
  }

  Future<void> _showEditRevenueDialog(RevenueEntity item) async {
    if (!_isManualRevenueEntry(item)) {
      _showManualOnlyWarning();
      return;
    }

    // Check if date falls in finalized period
    if (_isDateInFinalizedPeriod(item.date)) {
      AppSnackBar.warning(
        context,
        _translateWithFallback(
          'accounting.period_finalized_readonly',
          'Kỳ kế toán đã chốt sổ, không thể chỉnh sửa',
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController(
      text: CurrencyFormatter.formatNumber(item.amount),
    );
    final descriptionController = TextEditingController(text: item.description);
    final documentNumberController = TextEditingController(
      text: item.documentNumber ?? '',
    );
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDocumentDate = item.documentDate;

    List<ReferenceItem> getMoneyChannels() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return state.references['moneyChannelTypes'] ?? const <ReferenceItem>[];
      }
      return const <ReferenceItem>[];
    }

    List<BusinessTypeDto> businessTypes = [];

    try {
      final result = await context
          .read<ProductBloc>()
          .repository
          .getBusinessTypes();
      businessTypes = List<BusinessTypeDto>.from(result);
    } catch (_) {
      businessTypes = [];
    }

    if (!mounted) return;

    String? selectedMoneyChannel = item.moneyChannel;
    final channels = getMoneyChannels();
    if ((selectedMoneyChannel ?? '').isNotEmpty &&
        !channels.any((c) => c.code == selectedMoneyChannel)) {
      selectedMoneyChannel = null;
    }
    String? selectedBusinessTypeId = item.businessTypeId;
    final businessTypeIds = businessTypes.map((e) => e.businessTypeId).toSet();
    if ((selectedBusinessTypeId ?? '').isNotEmpty &&
        !businessTypeIds.contains(selectedBusinessTypeId)) {
      selectedBusinessTypeId = null;
    }

    bool isSubmitting = false;
    bool removeImage = false;
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.edit_revenue')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  label: l10n.translate('accounting.revenue_amount'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: descriptionController,
                  label: l10n.translate('accounting.revenue_description'),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildStringDropdownField(
                  label: l10n.translate('accounting.channel'),
                  value: selectedMoneyChannel,
                  options: getMoneyChannels(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMoneyChannel = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedBusinessTypeId,
                  decoration: InputDecoration(
                    labelText: l10n.translate(
                      'accounting.revenue_business_type',
                    ),
                  ),
                  items: businessTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type.businessTypeId,
                          child: Text(
                            type.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedBusinessTypeId = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _buildDateSelectorTile(
                  title: l10n.translate('accounting.revenue_date'),
                  dialogCtx: dialogCtx,
                  value: selectedDate,
                  initialDate: selectedDate,
                  readOnly: true,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDate = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: documentNumberController,
                  label: l10n.translate('accounting.document_number'),
                  hintText: l10n.translate('accounting.document_number_hint'),
                ),
                const SizedBox(height: AppSpacing.md),
                // Image upload section
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                              l10n.translate('accounting.select_image'),
                            ),
                            onPressed: () => _pickImage(
                              ImageSource.gallery,
                              setDialogState,
                              (file) {
                                selectedImage = file;
                                removeImage = false;
                              },
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              l10n.translate('accounting.take_photo'),
                            ),
                            onPressed: () => _pickImage(
                              ImageSource.camera,
                              setDialogState,
                              (file) {
                                selectedImage = file;
                                removeImage = false;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedImage != null ||
                        (item.imagePath?.isNotEmpty == true && !removeImage))
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => setDialogState(() {
                          selectedImage = null;
                          removeImage = true;
                        }),
                      ),
                  ],
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Image.file(
                      selectedImage!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ] else if (item.imagePath?.isNotEmpty == true &&
                    !removeImage) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Builder(
                      builder: (context) {
                        final imageSource = _resolveImageSource(item.imagePath);
                        if (imageSource == null) {
                          return const SizedBox(
                            height: 120,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }
                        return _buildDetailImage(imageSource, height: 120);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final amount =
                          (CurrencyFormatter.parse(amountController.text) ?? 0)
                              .toDouble();
                      if (amount <= 0 || (selectedMoneyChannel ?? '').isEmpty) {
                        setDialogState(() => isSubmitting = false);
                        return;
                      }

                      // Document number duplicate check
                      final docNum = documentNumberController.text.trim();
                      if (docNum.isNotEmpty) {
                        final canProceed = await checkDocumentNumberAndConfirm(
                          context,
                          documentNumber: docNum,
                          excludeRevenueId: item.id,
                        );
                        if (!canProceed) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          return;
                        }
                      }

                      if (!mounted || !dialogCtx.mounted) {
                        return;
                      }

                      final locationId = context
                          .read<BusinessContext>()
                          .currentBusinessId;
                      context.read<RevenueBloc>().add(
                        UpdateManualRevenueRequested(
                          idempotencyKey: const Uuid().v4(),
                          revenueId: item.id,
                          body: {
                            'businessLocationId':
                                int.tryParse(locationId ?? '') ??
                                item.locationId,
                            'amount': amount,
                            'revenueDate': DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDate),
                            'documentDate': selectedDocumentDate == null
                                ? null
                                : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(selectedDocumentDate!),
                            'description': descriptionController.text.trim(),
                            'moneyChannel': selectedMoneyChannel,
                            if (documentNumberController.text.trim().isNotEmpty)
                              'documentNumber': documentNumberController.text
                                  .trim(),
                            'removeImage': removeImage,
                            if ((selectedBusinessTypeId ?? '').isNotEmpty)
                              'businessTypeId': selectedBusinessTypeId,
                          },
                          image: selectedImage,
                        ),
                      );
                      Navigator.of(dialogCtx).pop();
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );

    amountController.dispose();
    descriptionController.dispose();
    documentNumberController.dispose();
  }
}

enum _EntryCreateMode { manual, aiDraft }

class _ImageSource {
  final String value;
  final bool isNetwork;

  const _ImageSource._({required this.value, required this.isNetwork});

  factory _ImageSource.network(String value) {
    return _ImageSource._(value: value, isNetwork: true);
  }

  factory _ImageSource.file(String value) {
    return _ImageSource._(value: value, isNetwork: false);
  }
}

class _VoicePlayBtn extends StatefulWidget {
  final AudioPlayer player;
  final bool isDisabled;
  final VoidCallback onTap;
  final String label;

  const _VoicePlayBtn({
    required this.player,
    required this.isDisabled,
    required this.onTap,
    required this.label,
  });

  @override
  State<_VoicePlayBtn> createState() => _VoicePlayBtnState();
}

class _VoicePlayBtnState extends State<_VoicePlayBtn> {
  bool _isPlaying = false;
  late final StreamSubscription<PlayerState> _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: widget.isDisabled ? null : widget.onTap,
      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
      label: Text(widget.label),
    );
  }
}
