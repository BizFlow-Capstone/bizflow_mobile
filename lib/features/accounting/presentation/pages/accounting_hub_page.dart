import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:bizflow_mobile/core/reference/presentation/bloc/reference_bloc.dart';
import 'package:bizflow_mobile/core/reference/presentation/bloc/reference_event.dart';
import 'package:bizflow_mobile/core/reference/presentation/bloc/reference_state.dart';
import 'package:bizflow_mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:bizflow_mobile/features/revenue/presentation/bloc/revenue_bloc.dart';
import 'package:bizflow_mobile/features/cost/presentation/bloc/cost_bloc.dart';
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
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/cache/sync_status_controller.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../bloc/accounting_period_bloc.dart';
import '../widgets/accounting_cost_revenue_tab.dart';
import '../widgets/accounting_gl_tab.dart';
import '../widgets/accounting_period_tab.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';

class AccountingHubPage extends StatefulWidget {
  const AccountingHubPage({super.key});

  @override
  State<AccountingHubPage> createState() => _AccountingHubPageState();
}

class _AccountingHubPageState extends State<AccountingHubPage>
    with SingleTickerProviderStateMixin {
  static const String _featureManualRevenue =
      SubscriptionFeatureCodes.manualRevenue;

  late final TabController _tabController;

  // Period BLoC data is managed by AccountingPeriodBloc
  // Other tabs still use local/mock state for now
  final AudioRecorder _voiceRecorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  bool _isVoiceRecording = false;
  String? _lastVoicePath;
  String? _lastVoiceTranscript;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    SyncStatusController().setManualRefreshCallback(_refreshCurrentTab);

    _tabController.addListener(_handleTabSelection);

    // Initial load of first tab and references only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTab(0);
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
      case 2: // Doanh thu
        context.read<RevenueBloc>().add(
          LoadRevenuesRequested(businessLocationId: locationId),
        );
        break;
      case 3: // Chi phí
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
    if (!mounted) return;
    SyncStatusController().startSync();
    try {
      _loadReferences();
      _loadTab(_tabController.index);
      SyncStatusController().endSync(updatedAt: DateTime.now());
    } catch (_) {
      SyncStatusController().endSync(hasError: true);
    }
  }

  @override
  void dispose() {
    SyncStatusController().setManualRefreshCallback(null);
    _voiceRecorder.dispose();
    _voicePlayer.dispose();
    _tabController.dispose();
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

  void _applyRevenueTranscript({
    required String transcript,
    required TextEditingController amountController,
    required TextEditingController descriptionController,
  }) {
    final amount = _extractAmountFromTranscript(transcript);
    if (amount != null && amount > 0) {
      amountController.text = CurrencyFormatter.formatNumber(amount);
    }
    if (descriptionController.text.trim().isEmpty) {
      descriptionController.text = transcript;
    }
  }

  void _applyCostTranscript({
    required String transcript,
    required TextEditingController amountController,
    required TextEditingController descriptionController,
  }) {
    final amount = _extractAmountFromTranscript(transcript);
    if (amount != null && amount > 0) {
      amountController.text = CurrencyFormatter.formatNumber(amount);
    }
    if (descriptionController.text.trim().isEmpty) {
      descriptionController.text = transcript;
    }
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
              OutlinedButton.icon(
                onPressed: _lastVoicePath == null ? null : _playLastVoiceRecord,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.translate('accounting.voice_play_back')),
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
    final ok = await _confirmAction(
      title: l10n.translate('accounting.confirm_title'),
      message: l10n.translate('accounting.confirm_delete_revenue'),
    );
    if (!ok) return;

    final allowed = await _checkFeatureAccess(_featureManualRevenue);
    if (!allowed) return;

    if (!mounted) return;
    context.read<RevenueBloc>().add(
      DeleteManualRevenueRequested(revenueId: item.id),
    );
  }

  Future<void> _onDeleteCost(CostEntity item) async {
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
              _showSuccess(
                l10n.translate('accounting.revenue_created_success'),
              );
              final locationId = context
                  .read<BusinessContext>()
                  .currentBusinessId;
              if (locationId != null) {
                context.read<RevenueBloc>().add(
                  LoadRevenuesRequested(businessLocationId: locationId),
                );
              }
            } else if (state is RevenueUpdated) {
              _showSuccess(
                l10n.translate('accounting.revenue_updated_success'),
              );
              final locationId = context
                  .read<BusinessContext>()
                  .currentBusinessId;
              if (locationId != null) {
                context.read<RevenueBloc>().add(
                  LoadRevenuesRequested(businessLocationId: locationId),
                );
              }
            } else if (state is RevenueDeleted) {
              _showSuccess(
                l10n.translate('accounting.revenue_deleted_success'),
              );
            } else if (state is RevenueError) {
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
                        List<RevenueEntity> revenueEntities = [];
                        if (revenueState is RevenuesLoaded) {
                          revenueEntities = revenueState.revenues;
                        }

                        return AccountingCostRevenueTab(
                          mode: AccountingCostRevenueMode.revenue,
                          revenues: revenueEntities,
                          costs: const <CostEntity>[],
                          onAddRevenue: _showAddRevenueDialog,
                          onAddCost: _showAddCostDialog,
                          onEditRevenue: _showEditRevenueDialog,
                          onTapRevenue: _showRevenueDetailDialog,
                          onDeleteRevenue: _onDeleteRevenue,
                          onEditCost: _showEditCostDialog,
                          onDeleteCost: _onDeleteCost,
                        );
                      },
                    ),
                    BlocBuilder<CostBloc, CostState>(
                      builder: (context, costState) {
                        List<CostEntity> costEntities = [];
                        if (costState is CostsLoaded) {
                          costEntities = costState.costs;
                        }

                        return AccountingCostRevenueTab(
                          mode: AccountingCostRevenueMode.cost,
                          revenues: const <RevenueEntity>[],
                          costs: costEntities,
                          onAddRevenue: _showAddRevenueDialog,
                          onAddCost: _showAddCostDialog,
                          onEditRevenue: _showEditRevenueDialog,
                          onTapRevenue: _showRevenueDetailDialog,
                          onDeleteRevenue: _onDeleteRevenue,
                          onEditCost: _showEditCostDialog,
                          onDeleteCost: _onDeleteCost,
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

  Future<void> _showAddRevenueDialog() async {
    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final referenceOrderIdController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDocumentDate;
    String? selectedMoneyChannel;
    String? selectedBusinessTypeId;
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

    List<String> getMoneyChannels() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return state.references['moneyChannelTypes'] ?? const <String>[];
      }
      return const <String>[];
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.add_revenue')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildVoiceAssistControls(
                  l10n: l10n,
                  dialogCtx: dialogCtx,
                  setDialogState: setDialogState,
                  onTranscriptReady: (transcript) {
                    _applyRevenueTranscript(
                      transcript: transcript,
                      amountController: amountController,
                      descriptionController: descriptionController,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.revenue_amount'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.revenue_description'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedMoneyChannel,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.channel'),
                  ),
                  items: getMoneyChannels()
                      .map(
                        (channel) => DropdownMenuItem<String>(
                          value: channel,
                          child: Text(channel),
                        ),
                      )
                      .toList(),
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
                TextField(
                  controller: referenceOrderIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Order ID (optional)',
                    hintText: 'Ví dụ: 123',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.translate('accounting.revenue_date')),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chứng từ'),
                  subtitle: Text(
                    selectedDocumentDate == null
                        ? l10n.translate('common.no_data')
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDocumentDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDocumentDate != null)
                        IconButton(
                          onPressed: () =>
                              setDialogState(() => selectedDocumentDate = null),
                          icon: const Icon(Icons.close),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDocumentDate ?? selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDocumentDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountString = amountController.text.replaceAll(',', '');
                final amount = double.tryParse(amountString) ?? 0;
                if (amount <= 0) return;

                if ((selectedMoneyChannel ?? '').trim().isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.translate('accounting.money_channel_required'),
                      ),
                    ),
                  );
                  return;
                }

                final ok = await _confirmAction(
                  title: l10n.translate('accounting.confirm_title'),
                  message: l10n.translate('accounting.confirm_create_revenue'),
                );
                if (!ok || !context.mounted) return;

                final allowed = await _checkFeatureAccess(
                  _featureManualRevenue,
                );
                if (!allowed) return;

                if (!mounted) return;
                if (!dialogCtx.mounted) return;

                // Use outer page context — dialog ctx has no Providers
                final locationId = context
                    .read<BusinessContext>()
                    .currentBusinessId;
                final referenceOrderId = int.tryParse(
                  referenceOrderIdController.text.trim(),
                );

                context.read<RevenueBloc>().add(
                  CreateManualRevenueRequested(
                    body: {
                      'businessLocationId': int.tryParse(locationId ?? '') ?? 0,
                      'amount': amount,
                      'revenueDate': DateFormat(
                        'yyyy-MM-dd',
                      ).format(selectedDate),
                      if (selectedDocumentDate != null)
                        'documentDate': DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDocumentDate!),
                      'description': descriptionController.text,
                      'moneyChannel': selectedMoneyChannel,
                      if ((selectedBusinessTypeId ?? '').isNotEmpty)
                        'businessTypeId': selectedBusinessTypeId,
                      if (referenceOrderId != null) 'referenceType': 'order',
                      if (referenceOrderId != null)
                        'referenceId': referenceOrderId,
                    },
                  ),
                );
                Navigator.of(dialogCtx).pop();
              },
              child: Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<OrderEntity?> _loadLinkedOrder(RevenueEntity revenue) async {
    final refType = revenue.referenceType?.trim().toLowerCase();
    final refId = revenue.referenceId;
    if (refType != 'order' || refId == null || refId <= 0) return null;

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
    DateTime selectedDate = DateTime.now();
    DateTime? selectedDocumentDate;
    String? selectedCostType;
    String? selectedPaymentMethod;

    List<String> getCostTypes() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['costTypes'] ?? const <String>[])
            .toSet()
            .toList();
      }
      return const <String>[];
    }

    List<String> getPaymentMethods() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['paymentMethods'] ?? const <String>[])
            .toSet()
            .toList();
      }
      return const <String>[];
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.add_cost')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildVoiceAssistControls(
                  l10n: l10n,
                  dialogCtx: dialogCtx,
                  setDialogState: setDialogState,
                  onTranscriptReady: (transcript) {
                    _applyCostTranscript(
                      transcript: transcript,
                      amountController: amountController,
                      descriptionController: descriptionController,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.description'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.amount'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedCostType,
                  decoration: const InputDecoration(labelText: 'Loại chi phí'),
                  items: getCostTypes()
                      .where(
                        (c) => c.toLowerCase() != 'import',
                      ) // Backend excludes 'import'
                      .map(
                        (val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(val),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCostType = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Phương thức thanh toán',
                  ),
                  items: getPaymentMethods()
                      .map(
                        (val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(val),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedPaymentMethod = value),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chi'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chứng từ'),
                  subtitle: Text(
                    selectedDocumentDate == null
                        ? l10n.translate('common.no_data')
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDocumentDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDocumentDate != null)
                        IconButton(
                          onPressed: () =>
                              setDialogState(() => selectedDocumentDate = null),
                          icon: const Icon(Icons.close),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDocumentDate ?? selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDocumentDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    (CurrencyFormatter.parse(amountController.text) ?? 0)
                        .toDouble();
                if (descriptionController.text.trim().isEmpty ||
                    amount <= 0 ||
                    selectedCostType == null ||
                    selectedPaymentMethod == null) {
                  return;
                }

                final locationId = context
                    .read<BusinessContext>()
                    .currentBusinessId;
                context.read<CostBloc>().add(
                  CreateManualCostRequested(
                    body: {
                      'businessLocationId': int.tryParse(locationId ?? '') ?? 0,
                      'amount': amount,
                      'costDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                      if (selectedDocumentDate != null)
                        'documentDate': DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDocumentDate!),
                      'description': descriptionController.text,
                      'costType': selectedCostType,
                      'paymentMethod': selectedPaymentMethod,
                    },
                  ),
                );
                Navigator.pop(dialogCtx);
              },
              child: Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditCostDialog(CostEntity item) async {
    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController(
      text: CurrencyFormatter.formatNumber(item.amount),
    );
    final descriptionController = TextEditingController(text: item.description);
    DateTime selectedDate = item.date;
    DateTime? selectedDocumentDate = item.documentDate;
    String? selectedCostType;
    String? selectedPaymentMethod;

    List<String> getCostTypes() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['costTypes'] ?? const <String>[])
            .toSet()
            .toList();
      }
      return const <String>[];
    }

    List<String> getPaymentMethods() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return (state.references['paymentMethods'] ?? const <String>[])
            .toSet()
            .toList();
      }
      return const <String>[];
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.edit_cost')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.description'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.amount'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedCostType,
                  decoration: const InputDecoration(labelText: 'Loại chi phí'),
                  items: getCostTypes()
                      .where((c) => c.toLowerCase() != 'import')
                      .map(
                        (val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(val),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCostType = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Phương thức thanh toán',
                  ),
                  items: getPaymentMethods()
                      .map(
                        (val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(val),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedPaymentMethod = value),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chi'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chứng từ'),
                  subtitle: Text(
                    selectedDocumentDate == null
                        ? l10n.translate('common.no_data')
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDocumentDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDocumentDate != null)
                        IconButton(
                          onPressed: () =>
                              setDialogState(() => selectedDocumentDate = null),
                          icon: const Icon(Icons.close),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDocumentDate ?? selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDocumentDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    (CurrencyFormatter.parse(amountController.text) ?? 0)
                        .toDouble();
                if (descriptionController.text.trim().isEmpty ||
                    amount <= 0 ||
                    selectedCostType == null ||
                    selectedPaymentMethod == null) {
                  return;
                }

                final ok = await _confirmAction(
                  title: l10n.translate('accounting.confirm_title'),
                  message: l10n.translate('accounting.confirm_update_item'),
                );
                if (!ok) return;

                if (!mounted) return;
                if (!dialogCtx.mounted) return;

                // Use outer context to read BLoC safely
                context.read<CostBloc>().add(
                  UpdateManualCostRequested(
                    costId: item.id,
                    body: {
                      'amount': amount,
                      'costDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                      'documentDate': selectedDocumentDate == null
                          ? null
                          : DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDocumentDate!),
                      'description': descriptionController.text.trim(),
                      'costType': selectedCostType ?? item.type,
                      'paymentMethod':
                          selectedPaymentMethod ?? item.paymentMethod,
                      'removeDocument': false,
                    },
                  ),
                );
                Navigator.of(dialogCtx).pop();
              },
              child: Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevenueDetailDialog(RevenueEntity revenue) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('REV-${revenue.id}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Số tiền: ${CurrencyFormatter.formatVND(revenue.amount)}'),
                const SizedBox(height: 6),
                Text('Mô tả: ${revenue.description}'),
                const SizedBox(height: 6),
                Text('Kênh tiền: ${revenue.moneyChannel ?? '-'}'),
                const SizedBox(height: 6),
                Text(
                  'Ngày chứng từ: ${revenue.documentDate == null ? '-' : DateFormat('yyyy-MM-dd').format(revenue.documentDate!)}',
                ),
                const SizedBox(height: 6),
                Text('Loại hình KD: ${revenue.businessTypeName ?? '-'}'),
                const SizedBox(height: 6),
                Text('Loại tham chiếu: ${revenue.referenceType ?? '-'}'),
                const SizedBox(height: 6),
                Text(
                  'Mã tham chiếu: ${revenue.referenceCode ?? revenue.referenceId?.toString() ?? '-'}',
                ),
                const SizedBox(height: 12),
                if ((revenue.referenceType ?? '').toLowerCase() == 'order' &&
                    (revenue.referenceId ?? 0) > 0) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Order detail',
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
                        return const Text('Không tải được chi tiết đơn hàng');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order.id}'),
                          const SizedBox(height: 4),
                          Text('Trạng thái: ${order.status}'),
                          const SizedBox(height: 4),
                          Text(
                            'Tổng: ${CurrencyFormatter.formatVND(order.totalAmount)}',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.translate('common.close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRevenueDialog(RevenueEntity item) async {
    final l10n = AppLocalizations.of(context);
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final amountController = TextEditingController(
      text: CurrencyFormatter.formatNumber(item.amount),
    );
    final descriptionController = TextEditingController(text: item.description);
    DateTime selectedDate = item.date;
    DateTime? selectedDocumentDate = item.documentDate;

    List<String> getMoneyChannels() {
      final state = context.read<ReferenceBloc>().state;
      if (state is ReferenceLoaded) {
        return state.references['moneyChannelTypes'] ?? const <String>[];
      }
      return const <String>[];
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
        !channels.contains(selectedMoneyChannel)) {
      selectedMoneyChannel = null;
    }
    String? selectedBusinessTypeId = item.businessTypeId;
    final businessTypeIds = businessTypes.map((e) => e.businessTypeId).toSet();
    if ((selectedBusinessTypeId ?? '').isNotEmpty &&
        !businessTypeIds.contains(selectedBusinessTypeId)) {
      selectedBusinessTypeId = null;
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.edit_revenue')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.revenue_amount'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.revenue_description'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedMoneyChannel,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.channel'),
                  ),
                  items: getMoneyChannels()
                      .map(
                        (channel) => DropdownMenuItem<String>(
                          value: channel,
                          child: Text(channel),
                        ),
                      )
                      .toList(),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.translate('accounting.revenue_date')),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chứng từ'),
                  subtitle: Text(
                    selectedDocumentDate == null
                        ? l10n.translate('common.no_data')
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDocumentDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDocumentDate != null)
                        IconButton(
                          onPressed: () =>
                              setDialogState(() => selectedDocumentDate = null),
                          icon: const Icon(Icons.close),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDocumentDate ?? selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDocumentDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    (CurrencyFormatter.parse(amountController.text) ?? 0)
                        .toDouble();
                if (amount <= 0 || (selectedMoneyChannel ?? '').isEmpty) return;

                final ok = await _confirmAction(
                  title: l10n.translate('accounting.confirm_title'),
                  message: l10n.translate('accounting.confirm_update_revenue'),
                );
                if (!ok) return;

                final allowed = await _checkFeatureAccess(
                  _featureManualRevenue,
                );
                if (!allowed) return;

                if (!mounted) return;
                if (!dialogCtx.mounted) return;

                final locationId = context
                    .read<BusinessContext>()
                    .currentBusinessId;
                context.read<RevenueBloc>().add(
                  UpdateManualRevenueRequested(
                    revenueId: item.id,
                    body: {
                      'businessLocationId':
                          int.tryParse(locationId ?? '') ?? item.locationId,
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
                      if ((selectedBusinessTypeId ?? '').isNotEmpty)
                        'businessTypeId': selectedBusinessTypeId,
                    },
                  ),
                );
                Navigator.of(dialogCtx).pop();
              },
              child: Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}
