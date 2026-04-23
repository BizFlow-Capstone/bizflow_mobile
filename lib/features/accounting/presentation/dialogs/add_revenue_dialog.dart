import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../product/data/models/business_type_model.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../revenue/presentation/bloc/revenue_bloc.dart';

Future<void> showAddRevenueDialog({
  required BuildContext context,
  required Future<bool> Function({
    required String title,
    required String message,
  }) confirmAction,
  required Future<bool> Function() checkFeatureAccess,
}) async {
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
  File? selectedImage;
  var isSubmitting = false;
  List<BusinessTypeDto> businessTypes = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source, void Function(void Function()) setDialogState) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
    if (pickedFile != null) {
      setDialogState(() => selectedImage = File(pickedFile.path));
    }
  }

  try {
    final result =
        await context.read<ProductBloc>().repository.getBusinessTypes();
    businessTypes = List<BusinessTypeDto>.from(result);
  } catch (_) {
    businessTypes = [];
  }

  if (!context.mounted) return;

  List<ReferenceItem> getMoneyChannels() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      return state.references['moneyChannelTypes'] ?? const <ReferenceItem>[];
    }
    return const <ReferenceItem>[];
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
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.translate('accounting.select_image')),
                    onPressed: () => pickImage(ImageSource.gallery, setDialogState),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.translate('accounting.take_photo')),
                    onPressed: () => pickImage(ImageSource.camera, setDialogState),
                  ),
                ],
              ),
              if (selectedImage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedImage!,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: selectedMoneyChannel,
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.channel'),
                ),
                items: getMoneyChannels()
                    .where((item) => item.label.trim().isNotEmpty)
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.code,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => selectedMoneyChannel = value);
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
                  setDialogState(() => selectedBusinessTypeId = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: referenceOrderIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      l10n.translate('accounting.reference_order_id'),
                  hintText: l10n.translate(
                    'accounting.reference_order_id_hint',
                  ),
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
                title: Text(l10n.translate('accounting.document_date')),
                subtitle: Text(
                  selectedDocumentDate == null
                      ? l10n.translate('common.no_data')
                      : DateFormat('yyyy-MM-dd')
                          .format(selectedDocumentDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedDocumentDate != null)
                      IconButton(
                        onPressed: () => setDialogState(
                          () => selectedDocumentDate = null,
                        ),
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
            onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setDialogState(() => isSubmitting = true);
                    final amountString =
                        amountController.text.replaceAll(',', '');
                    final amount = double.tryParse(amountString) ?? 0;
                    if (amount <= 0) {
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    if ((selectedMoneyChannel ?? '').trim().isEmpty) {
                      await AppDialog.show(
                        dialogCtx,
                        title: l10n.translate('common.warning'),
                        message: l10n.translate(
                          'accounting.money_channel_required',
                        ),
                        type: AppDialogType.warning,
                      );
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    final ok = await confirmAction(
                      title: l10n.translate('accounting.confirm_title'),
                      message: l10n.translate(
                        'accounting.confirm_create_revenue',
                      ),
                    );
                    if (!ok || !context.mounted) {
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    final allowed = await checkFeatureAccess();
                    if (!allowed) {
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    if (!context.mounted) return;
                    if (!dialogCtx.mounted) return;

                    final locationId =
                        context.read<BusinessContext>().currentBusinessId;
                    final referenceOrderId = int.tryParse(
                      referenceOrderIdController.text.trim(),
                    );

                    context.read<RevenueBloc>().add(
                      CreateManualRevenueRequested(
                        body: {
                          'businessLocationId': int.tryParse(locationId ?? '') ?? 0,
                          'amount': amount,
                          'revenueDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                          if (selectedDocumentDate != null)
                            'documentDate': DateFormat('yyyy-MM-dd').format(selectedDocumentDate!),
                          'description': descriptionController.text,
                          'moneyChannel': selectedMoneyChannel,
                          if ((selectedBusinessTypeId ?? '').isNotEmpty)
                            'businessTypeId': selectedBusinessTypeId,
                          if (referenceOrderId != null)
                            'referenceType': 'order',
                          if (referenceOrderId != null)
                            'referenceId': referenceOrderId,
                        },
                        image: selectedImage,
                      ),
                    );
                    Navigator.of(dialogCtx).pop();
                    if (dialogCtx.mounted) {
                      setDialogState(() => isSubmitting = false);
                    }
                  },
            child: Text(l10n.translate('common.save')),
          ),
        ],
      ),
    ),
  );
}
