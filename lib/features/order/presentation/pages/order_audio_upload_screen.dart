import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_form_screen.dart';

class OrderAudioUploadScreen extends StatefulWidget {
  const OrderAudioUploadScreen({super.key});

  @override
  State<OrderAudioUploadScreen> createState() => _OrderAudioUploadScreenState();
}

class _OrderAudioUploadScreenState extends State<OrderAudioUploadScreen> {
  String? _selectedFileName;
  bool _isProcessing = false;
  String? _inlineError;

  String _resolveDirectNetworkError(AppLocalizations l10n, Object error) {
    if (!ConnectivityService().isOnline) {
      return l10n.translate('error.no_internet');
    }
    if (error is ApiException && error.statusCode == -3) {
      return l10n.translate('error.no_internet');
    }
    final parsed = ApiErrorMessageParser.parse(
      error,
      fallback: l10n.translate('common.error_occurred'),
    );
    final normalized = parsed.toLowerCase();
    if (normalized.contains('khong ket noi') ||
        normalized.contains('network') ||
        normalized.contains('connection')) {
      return l10n.translate('error.no_internet');
    }
    return parsed;
  }

  Widget _buildInlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result == null || result.files.isEmpty || !mounted) return;

      final selected = result.files.single;
      final selectedPath = selected.path;

      setState(() {
        _selectedFileName = selected.name;
        _inlineError = null;
      });

      if (selectedPath == null || selectedPath.trim().isEmpty) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(
            context,
          ).translate('common.error_occurred'),
          type: AppSnackBarType.error,
        );
        return;
      }

      await _parseAndNavigate(audioFile: File(selectedPath));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _parseAndNavigate({required File audioFile}) async {
    final l10n = AppLocalizations.of(context);
    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    if (locationId == null || locationId <= 0) {
      AppSnackBar.show(
        context,
        message: AppLocalizations.of(
          context,
        ).translate('common.error_occurred'),
        type: AppSnackBarType.error,
      );
      return;
    }

    if (!ConnectivityService().isOnline) {
      if (!mounted) return;
      setState(() {
        _inlineError = l10n.translate('error.no_internet');
      });
      return;
    }

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
            .where(
              (item) =>
                  item.matched &&
                  (item.customerName?.trim().isNotEmpty ?? false),
            )
            .map((item) => item.customerName!.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => ''),
        items: matchedItems.map((item) {
          final quantity = item.quantity <= 0 ? 1 : item.quantity;
          final calculatedPrice =
              item.unitPrice ??
              ((item.lineTotal ?? 0) > 0 ? (item.lineTotal! / quantity) : 0);
          return OrderItemEntity(
            productId: item.productId ?? '',
            saleItemId: item.saleItemId,
            unitName: item.unit,
            productName: item.productName ?? '',
            price: calculatedPrice,
            quantity: quantity,
            discount: 0,
          );
        }).toList(),
        totalAmount: result.totalAmount,
        hasDebt: hasDebt,
        aiConfidence: result.confidence,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrderFormScreen(inputType: 'audio', initialOrder: initialOrder),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _inlineError = _resolveDirectNetworkError(l10n, error);
      });
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
        title: Text(l10n.translate('order_create.audio_upload_title')),
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
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.translate('order_create.audio_upload_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_selectedFileName != null)
                  Text(
                    _selectedFileName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickAudioFile,
                    icon: const Icon(Icons.audio_file),
                    label: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.translate('order_create.audio_upload_btn')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 16),
                  _buildInlineError(_inlineError!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
