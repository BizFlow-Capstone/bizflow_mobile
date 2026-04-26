import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/services/audio_public_storage_service.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../cost/data/models/ai_draft_cost_dto.dart';
import '../../../cost/presentation/bloc/cost_bloc.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../core/reference/data/reference_item.dart';

// Extracted Cost AI Draft Dialog
class AIDraftCostDialog extends StatefulWidget {
  final List<AiDraftCostItemDto> voiceItems;
  final List<ReferenceItem> Function() getMoneyChannels;
  final List<ReferenceItem> Function() getCostTypes;
  final BuildContext parentContext;

  const AIDraftCostDialog({
    super.key,
    required this.voiceItems,
    required this.getMoneyChannels,
    required this.getCostTypes,
    required this.parentContext,
  });

  @override
  State<AIDraftCostDialog> createState() => _AIDraftCostDialogState();
}

class _AIDraftCostDialogState extends State<AIDraftCostDialog> {
  late List<_CostAIDraft> drafts;
  final AudioRecorder _voiceRecorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _voicePlayerStateSub;
  bool _isVoiceRecording = false;
  bool _isVoiceProcessing = false;
  bool _isVoicePlaying = false;
  bool _hasVoiceParseResult = false;
  String? _lastVoicePath;
  String? _lastRawTranscript;
  String? _lastConfidence;

  String _confidenceLabel(AppLocalizations l10n, String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'high':
        return l10n.translate('accounting.ai_confidence_high');
      case 'medium':
        return l10n.translate('accounting.ai_confidence_medium');
      case 'low':
        return l10n.translate('accounting.ai_confidence_low');
      default:
        return normalized.isEmpty
            ? l10n.translate('accounting.ai_confidence_none')
            : normalized;
    }
  }

  Color _confidenceBackgroundColor(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'high':
        return AppColors.success.withValues(alpha: 0.14);
      case 'medium':
        return AppColors.warning.withValues(alpha: 0.16);
      case 'low':
        return AppColors.error.withValues(alpha: 0.14);
      default:
        return AppColors.divider;
    }
  }

  Color _confidenceTextColor(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'high':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  void initState() {
    super.initState();
    drafts = [];
    _voicePlayerStateSub = _voicePlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isVoicePlaying = state == PlayerState.playing;
      });
    });
    if (widget.voiceItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _populateFromAi(AppLocalizations.of(context));
      });
    }
  }

  @override
  void dispose() {
    _voicePlayerStateSub?.cancel();
    _voicePlayer.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  Future<Directory> _getVoiceRecordDirectory() async {
    Directory? baseDirectory;
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.music,
      );
      baseDirectory = dirs?.isNotEmpty == true ? dirs!.first : null;
    }
    baseDirectory ??= await getApplicationDocumentsDirectory();

    final recordDir = Directory('${baseDirectory.path}/BizFlowRecordings');
    if (!await recordDir.exists()) {
      await recordDir.create(recursive: true);
    }
    return recordDir;
  }

  String? _mapCostTypeFromAi(dynamic aiValue, List<ReferenceItem> available) {
    // Handle both string and object formats: {code, label}
    final raw = _extractStringFromDynamic(aiValue).trim();
    if (raw.isEmpty || available.isEmpty) return null;
    final lower = raw.toLowerCase();

    for (final item in available) {
      if (item.code.toLowerCase() == lower) return item.code;
    }

    for (final item in available) {
      final code = item.code.toLowerCase();
      final label = item.label.toLowerCase();
      if (code.contains(lower) || lower.contains(code) ||
          label.contains(lower) || lower.contains(label)) return item.code;
    }

    return null;
  }

  String _extractStringFromDynamic(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Try to extract 'code' first, then 'label'
      return ((value['code'] ?? value['label']) ?? '').toString().trim();
    }
    return value.toString().trim();
  }

  Future<void> _parseDraftFromAudioFile({
    required String audioPath,
    required AppLocalizations l10n,
  }) async {
    final aiAllowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.ai,
    );
    if (!aiAllowed || !mounted) return;

    final locationId = int.tryParse(
      context.read<BusinessContext>().currentBusinessId ?? '',
    );
    if (locationId == null || locationId <= 0) {
      AppSnackBar.warning(
        context,
        l10n.translate('home.please_select_location'),
      );
      return;
    }

    setState(() => _isVoiceProcessing = true);
    try {
      final result = await context
          .read<CostBloc>()
          .repository
          .parseDraftCostFromAudio(
            locationId: locationId,
            audioFile: File(audioPath),
          );
      debugPrint(
        'AIDraftCostDialog.parse result rawTranscript="${result.rawTranscript}" confidence="${result.confidence}"',
      );
      final channels = widget.getMoneyChannels();
      final costTypes = widget.getCostTypes();
      final rawTranscript = result.rawTranscript.trim();
      final fallbackRawFromItems = result.items
          .map((item) => (item.description ?? '').trim())
          .where((text) => text.isNotEmpty)
          .join(' | ');
      setState(() {
        _lastVoicePath = audioPath;
        _hasVoiceParseResult = true;
        _lastRawTranscript = rawTranscript.isNotEmpty
            ? rawTranscript
            : fallbackRawFromItems;
        _lastConfidence = result.confidence.trim();
        drafts
          ..clear()
          ..addAll(
            result.items.map((item) {
              return _CostAIDraft(
                description: (item.description ?? '').trim(),
                amountText: item.amount == null
                    ? ''
                    : CurrencyFormatter.formatNumber(item.amount!),
                moneyChannel: _mapMoneyChannelFromAi(
                  item.paymentMethod,
                  channels,
                ),
                costDate: DateTime.now(),
                documentDate: null,
                costTypeId: _mapCostTypeFromAi(item.costType, costTypes),
              );
            }),
          );
      });
      if (drafts.isEmpty) {
        AppSnackBar.info(context, l10n.translate('accounting.ai_draft_empty'));
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, ApiErrorMessageParser.parse(e));
    } finally {
      if (mounted) {
        setState(() => _isVoiceProcessing = false);
      }
    }
  }

  Future<void> _toggleVoiceCapture(AppLocalizations l10n) async {
    if (_isVoiceRecording) {
      final recordedPath = await _voiceRecorder.stop();
      setState(() => _isVoiceRecording = false);
      if (recordedPath == null || recordedPath.isEmpty) {
        AppSnackBar.warning(
          context,
          l10n.translate('accounting.voice_no_record_found'),
        );
        return;
      }
      final fileName = recordedPath.split(Platform.pathSeparator).last;
      final publicPath = await AudioPublicStorageService.saveToRecordings(
        sourcePath: recordedPath,
        displayName: fileName,
      );
      if (mounted && (publicPath ?? '').isNotEmpty) {
        AppSnackBar.info(
          context,
          l10n.translate(
            'accounting.audio_saved_to',
            params: {'path': publicPath!},
          ),
        );
      }
      await _parseDraftFromAudioFile(audioPath: recordedPath, l10n: l10n);
      return;
    }

    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      AppSnackBar.warning(
        context,
        l10n.translate('common.microphone_permission_required'),
      );
      return;
    }
    if (!await _voiceRecorder.hasPermission()) {
      return;
    }

    final recordDir = await _getVoiceRecordDirectory();
    final path =
        '${recordDir.path}/accounting_cost_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _voiceRecorder.start(const RecordConfig(), path: path);
    setState(() {
      _isVoiceRecording = true;
      _lastVoicePath = path;
    });
  }

  Future<void> _pickAndParseAudioFile(AppLocalizations l10n) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['m4a', 'mp3', 'wav', 'aac', 'ogg'],
    );

    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    await _parseDraftFromAudioFile(audioPath: selectedPath, l10n: l10n);
  }

  Future<void> _replayLastVoice(AppLocalizations l10n) async {
    final path = _lastVoicePath;
    if (path == null || path.isEmpty) {
      AppSnackBar.info(
        context,
        l10n.translate('accounting.voice_no_record_found'),
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      AppSnackBar.warning(
        context,
        l10n.translate('accounting.voice_no_record_found'),
      );
      return;
    }

    if (_isVoicePlaying) {
      await _voicePlayer.stop();
      return;
    }

    await _voicePlayer.stop();
    await _voicePlayer.play(DeviceFileSource(path));
  }

  void _populateFromAi(AppLocalizations l10n) {
    final items = widget.voiceItems;
    if (items.isEmpty) {
      AppSnackBar.info(context, l10n.translate('accounting.ai_draft_empty'));
      return;
    }
    final channels = widget.getMoneyChannels();
    setState(() {
      drafts
        ..clear()
        ..addAll(
          items.map((item) {
            return _CostAIDraft(
              description: (item.description ?? '').trim(),
              amountText: item.amount == null
                  ? ''
                  : CurrencyFormatter.formatNumber(item.amount!),
              moneyChannel: _mapMoneyChannelFromAi(
                item.paymentMethod,
                channels,
              ),
              costDate: DateTime.now(),
              documentDate: null,
              costTypeId: item.costType,
            );
          }),
        );
    });
  }

  DateTime? _tryParseYmdDate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text);
    } catch (_) {
      return DateTime.tryParse(text);
    }
  }

  String? _mapMoneyChannelFromAi(dynamic aiValue, List<ReferenceItem> available) {
    // Handle both string and object formats: {code, label}
    final raw = _extractStringFromDynamic(aiValue).toLowerCase();
    if (raw.isEmpty || available.isEmpty) return null;

    bool matchCash(String source) =>
        source.contains('cash') ||
        source.contains('tiền mặt') ||
        source.contains('tien mat');
    bool matchBank(String source) =>
        source.contains('bank') ||
        source.contains('chuyển khoản') ||
        source.contains('chuyen khoan') ||
        source.contains('thẻ') ||
        source.contains('the') ||
        source.contains('ví') ||
        source.contains('vi');

    if (matchCash(raw)) {
      for (final item in available) {
        if (matchCash(item.code.toLowerCase()) || matchCash(item.label.toLowerCase())) return item.code;
      }
      return null;
    }
    if (matchBank(raw)) {
      for (final item in available) {
        if (matchBank(item.code.toLowerCase()) || matchBank(item.label.toLowerCase())) return item.code;
      }
      return null;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locationId = context.read<BusinessContext>().currentBusinessId;

    if (locationId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('accounting.ai_draft_cost_title')),
        ),
        body: Center(
          child: Text(l10n.translate('home.please_select_location')),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: Text(
            l10n.translate('accounting.ai_draft_cost_title'),
            style: AppTextStyles.titleMedium.copyWith(color: Colors.black),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isVoiceProcessing
                            ? null
                            : () => _toggleVoiceCapture(l10n),
                        icon: Icon(
                          _isVoiceRecording ? Icons.stop_circle : Icons.mic,
                        ),
                        label: Text(
                          _isVoiceRecording
                              ? l10n.translate('accounting.voice_stop_record')
                              : l10n.translate('accounting.voice_start_record'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isVoiceRecording || _isVoiceProcessing)
                            ? null
                            : () => _pickAndParseAudioFile(l10n),
                        icon: const Icon(Icons.library_music_outlined),
                        label: Text(
                          l10n.translate('accounting.voice_upload_file'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_isVoiceRecording || _isVoiceProcessing)
                        ? null
                        : () => _replayLastVoice(l10n),
                    icon: Icon(_isVoicePlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _isVoicePlaying
                          ? l10n.translate('accounting.voice_stop_playback')
                          : l10n.translate('accounting.voice_replay_latest'),
                    ),
                  ),
                ),
                if (_isVoiceProcessing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if ((_lastVoicePath ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate(
                      'accounting.audio_file_label',
                      params: {
                        'file': _lastVoicePath!
                            .split(Platform.pathSeparator)
                            .last,
                      },
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_hasVoiceParseResult) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.subtitles_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: SelectableText(
                            (_lastRawTranscript ?? '').isEmpty
                                ? l10n.translate(
                                    'accounting.voice_transcript_empty',
                                  )
                                : _lastRawTranscript!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _confidenceBackgroundColor(_lastConfidence),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      '${l10n.translate('accounting.ai_confidence')}: ${_confidenceLabel(l10n, _lastConfidence)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _confidenceTextColor(_lastConfidence),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (drafts.isEmpty)
                  Center(
                    child: Text(
                      l10n.translate('accounting.ai_draft_empty'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  //FIX: Use ValueKey to prevent draft from jumping when deleted
                  ...drafts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final draft = entry.value;
                    return _KeyedCostDraftItem(
                      key: ValueKey('cost_draft_${index}_${draft.id}'),
                      index: index,
                      draft: draft,
                      getMoneyChannels: widget.getMoneyChannels,
                      getCostTypes: widget.getCostTypes,
                      onDelete: () {
                        setState(() {
                          drafts.removeAt(index);
                        });
                      },
                      onSave: () => _saveDraft(context, l10n, locationId, index),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDraft(
    BuildContext context,
    AppLocalizations l10n,
    String locationId,
    int index,
  ) async {
    final draft = drafts[index];
    final amount =
        (CurrencyFormatter.parse(draft.amountText) ??
                double.tryParse(draft.amountText) ??
                0)
            .toDouble();

    // Validate: amount, description, moneyChannel bắt buộc.
    // costTypeId chỉ bắt buộc nếu cost types list có dữ liệu.
    final costTypeRequired =
        widget.getCostTypes().where((c) => c.label.trim().isNotEmpty).toList().isNotEmpty;
    if (amount <= 0 ||
        draft.description.trim().isEmpty ||
        (draft.moneyChannel ?? '').trim().isEmpty ||
        (costTypeRequired &&
            (draft.costTypeId ?? '').trim().isEmpty)) {
      AppSnackBar.info(
        context,
        l10n.translate('accounting.ai_draft_validation_failed'),
      );
      return;
    }

    setState(() {
      draft.isSaving = true;
    });

    try {
      final File? imageFile = (draft.imagePath ?? '').isNotEmpty
          ? File(draft.imagePath!)
          : null;
      await context.read<CostBloc>().repository.createManualCost(
        {
          'businessLocationId': int.tryParse(locationId) ?? 0,
          'amount': amount,
          'costDate': DateFormat('yyyy-MM-dd').format(draft.costDate),
          if (draft.documentDate != null)
            'documentDate': DateFormat('yyyy-MM-dd').format(draft.documentDate!),
          'description': draft.description.trim(),
          'paymentMethod': draft.moneyChannel,
          'costType': draft.costTypeId,
          if ((draft.documentNumber ?? '').trim().isNotEmpty)
            'documentNumber': draft.documentNumber!.trim(),
        },
        image: imageFile,
      );

      if (!mounted) return;
      AppSnackBar.success(
        context,
        l10n.translate('accounting.ai_draft_submit_success'),
      );
      context.read<CostBloc>().add(
        LoadCostsRequested(businessLocationId: locationId),
      );

      setState(() {
        drafts.removeAt(index);
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, ApiErrorMessageParser.parse(e));
    } finally {
      if (mounted) {
        setState(() {
          draft.isSaving = false;
        });
      }
    }
  }
}

//  Private draft item widget
class _KeyedCostDraftItem extends StatefulWidget {
  final int index;
  final _CostAIDraft draft;
  final List<ReferenceItem> Function() getMoneyChannels;
  final List<ReferenceItem> Function() getCostTypes;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  const _KeyedCostDraftItem({
    super.key,
    required this.index,
    required this.draft,
    required this.getMoneyChannels,
    required this.getCostTypes,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_KeyedCostDraftItem> createState() => _KeyedCostDraftItemState();
}

class _KeyedCostDraftItemState extends State<_KeyedCostDraftItem> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _documentNumberController;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      widget.draft.imagePath = picked.path;
    });
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.draft.description,
    );
    _amountController = TextEditingController(text: widget.draft.amountText);
    _documentNumberController = TextEditingController(
      text: widget.draft.documentNumber ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channels = widget.getMoneyChannels()
        .where((item) => item.label.trim().isNotEmpty)
        .toList();
    final costTypes = widget
        .getCostTypes()
        .where((c) => c.code.toLowerCase() != 'import' && c.label.trim().isNotEmpty)
        .toList();

    return Container(
      key: ValueKey('container_${widget.index}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.translate('accounting.ai_draft_item')} ${widget.index + 1}',
                style: AppTextStyles.labelMedium,
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              DateFormat('yyyy-MM-dd').format(widget.draft.costDate),
              style: AppTextStyles.bodySmall,
            ),
            trailing: const Icon(Icons.lock, size: 20),
            enabled: false,
            onTap: null,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '${l10n.translate('accounting.cost_description')} *',
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onChanged: (value) => widget.draft.description = value,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${l10n.translate('accounting.cost_amount')} *',
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onChanged: (value) => widget.draft.amountText = value,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _documentNumberController,
            decoration: InputDecoration(
              labelText: l10n.translate('accounting.document_number'),
              hintText: l10n.translate('accounting.document_number_hint'),
            ),
            onChanged: (value) => widget.draft.documentNumber = value,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: widget.draft.costTypeId,
            decoration: InputDecoration(
              labelText: '${l10n.translate('accounting.ai_cost_type')} *',
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            items: costTypes
                .where((item) => item.label.trim().isNotEmpty)
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type.code,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: (value) => widget.draft.costTypeId = value,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: widget.draft.moneyChannel,
            decoration: InputDecoration(
              labelText: '${l10n.translate('accounting.channel')} *',
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            items: channels
                .map(
                  (channel) => DropdownMenuItem<String>(
                    value: channel.code,
                    child: Text(channel.label),
                  ),
                )
                .toList(),
            onChanged: (value) => widget.draft.moneyChannel = value,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.translate('accounting.select_image')),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.translate('accounting.take_photo')),
              ),
            ],
          ),
          if ((widget.draft.imagePath ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Image.file(
                    File(widget.draft.imagePath!),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Material(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() => widget.draft.imagePath = null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.draft.isSaving ? null : widget.onSave,
              child: widget.draft.isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.translate('common.save')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostAIDraft {
  String description;
  String amountText;
  String? moneyChannel;
  DateTime costDate;
  DateTime? documentDate;
  String? documentNumber;
  String? costTypeId;
  String? imagePath;
  bool isSaving;

  _CostAIDraft({
    required this.description,
    required this.amountText,
    this.moneyChannel,
    required this.costDate,
    this.documentDate,
    this.documentNumber,
    this.costTypeId,
    this.imagePath,
    this.isSaving = false,
  });

  String get id => '$description$amountText$costDate';
}
