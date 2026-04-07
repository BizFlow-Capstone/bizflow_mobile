import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_form_screen.dart';

class OrderVoiceRecordScreen extends StatefulWidget {
  const OrderVoiceRecordScreen({super.key});

  @override
  State<OrderVoiceRecordScreen> createState() => _OrderVoiceRecordScreenState();
}

class _OrderVoiceRecordScreenState extends State<OrderVoiceRecordScreen> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    final l10n = AppLocalizations.of(context);

    if (_isRecording) {
      String? recordedPath;
      try {
        recordedPath = await _audioRecorder.stop();
      } finally {
        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }
      }

      if (recordedPath == null || recordedPath.trim().isEmpty) {
        if (mounted) {
          AppSnackBar.show(
            context,
            message: l10n.translate('common.error_occurred'),
            type: AppSnackBarType.error,
          );
        }
        return;
      }

      await _parseAndNavigate(audioFile: File(recordedPath), l10n: l10n);
      return;
    }

    final permissionStatus = await Permission.microphone.request();
    if (permissionStatus != PermissionStatus.granted) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.translate('common.error_occurred'),
          type: AppSnackBarType.warning,
        );
      }
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.translate('common.error_occurred'),
          type: AppSnackBarType.warning,
        );
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/order_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: path);

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _transcribedText = l10n.translate('common.loading');
    });
  }

  Future<void> _parseAndNavigate({
    required File audioFile,
    required AppLocalizations l10n,
  }) async {
    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    if (locationId == null || locationId <= 0) {
      AppSnackBar.show(
        context,
        message: l10n.translate('common.error_occurred'),
        type: AppSnackBarType.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _transcribedText = l10n.translate('common.loading');
    });

    try {
      final result = await context
          .read<OrderBloc>()
          .repository
          .parseDraftOrderFromAudio(
            locationId: locationId,
            audioFile: audioFile,
          );

      if (!mounted) return;

      final transcript = result.rawTranscript.trim();
      setState(() {
        _transcribedText = transcript.isNotEmpty
            ? transcript
            : l10n.translate('common.no_data');
      });

      final matchedItems = result.items
          .where(
            (item) =>
                item.matched &&
                ((item.productName?.trim().isNotEmpty ?? false) ||
                    (item.saleItemId ?? 0) > 0 ||
                    (item.productId?.trim().isNotEmpty ?? false)),
          )
          .toList();
      final hasDebt = result.items.any((item) => item.matched && item.isDebt);

      final initialOrder = _buildDraftOrder(
        locationId: locationId,
        rawTranscript: transcript,
        customerName: result.items
            .where((item) => item.matched && (item.customerName?.trim().isNotEmpty ?? false))
            .map((item) => item.customerName!.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => ''),
        items: matchedItems
            .map((item) {
              final quantity = item.quantity <= 0 ? 1 : item.quantity;
              final calculatedPrice =
                  item.unitPrice ??
                  ((item.lineTotal ?? 0) > 0
                      ? (item.lineTotal! / quantity)
                      : 0);
              return OrderItemEntity(
                productId: item.productId ?? '',
                saleItemId: item.saleItemId,
                unitName: item.unit,
                productName: item.productName ?? '',
                price: calculatedPrice,
                quantity: quantity,
                discount: 0,
              );
            })
            .toList(),
        totalAmount: result.totalAmount,
        hasDebt: hasDebt,
        aiConfidence: result.confidence,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrderFormScreen(inputType: 'voice', initialOrder: initialOrder),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.translate('common.error_occurred'),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  OrderEntity _buildDraftOrder({
    required int locationId,
    required String rawTranscript,
    required String customerName,
    required List<OrderItemEntity> items,
    double? totalAmount,
    bool hasDebt = false,
    String? aiConfidence,
  }) {
    final now = DateTime.now();
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final resolvedTotal = (totalAmount ?? subtotal).clamp(0, double.infinity);

    return OrderEntity(
      id: 'ai_draft_${now.millisecondsSinceEpoch}',
      locationId: locationId.toString(),
      locationName: BusinessContext().currentBusinessName ?? '',
      status: 'draft',
      items: items,
      subtotal: subtotal,
      discountAmount: 0,
      taxAmount: 0,
      totalAmount: resolvedTotal.toDouble(),
      debtAmount: hasDebt ? 1.0 : 0, // Mark as debt if any item is debt
      customerName: customerName.trim().isEmpty ? null : customerName.trim(),
      note: rawTranscript.isEmpty ? null : rawTranscript,
      aiConfidence: aiConfidence,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.voice_record_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.translate('order_create.voice_text_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _transcribedText.trim().isEmpty
                          ? l10n.translate('common.no_data')
                          : _transcribedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _isProcessing ? null : _toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.blue)
                              .withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isProcessing
                      ? l10n.translate('common.loading')
                      : (_isRecording
                            ? l10n.translate('order_create.voice_stop_btn')
                            : l10n.translate('order_create.voice_record_btn')),
                  style: TextStyle(
                    color: _isRecording ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
