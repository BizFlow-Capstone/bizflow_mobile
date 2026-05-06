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
import '../../../../shared/utils/date_formatter.dart';
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
  final refState = context.read<ReferenceBloc>().state;
  if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
    context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
  }

  await showDialog(
    context: context,
    builder: (_) => _AddRevenueDialog(
      confirmAction: confirmAction,
      checkFeatureAccess: checkFeatureAccess,
    ),
  );
}

class _AddRevenueDialog extends StatefulWidget {
  const _AddRevenueDialog({
    required this.confirmAction,
    required this.checkFeatureAccess,
  });

  final Future<bool> Function({required String title, required String message}) confirmAction;
  final Future<bool> Function() checkFeatureAccess;

  @override
  State<_AddRevenueDialog> createState() => _AddRevenueDialogState();
}

class _AddRevenueDialogState extends State<_AddRevenueDialog> {
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  late final TextEditingController referenceOrderIdController;
  late final TextEditingController documentNumberController;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDocumentDate;
  String? selectedMoneyChannel;
  String? selectedBusinessTypeId;
  File? selectedImage;
  bool isSubmitting = false;
  List<BusinessTypeDto> businessTypes = [];
  final ImagePicker _picker = ImagePicker();

  void _closeDialog([String? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    descriptionController = TextEditingController();
    referenceOrderIdController = TextEditingController();
    documentNumberController = TextEditingController();
    _loadBusinessTypes();
  }

  Future<void> _loadBusinessTypes() async {
    try {
      final result = await context.read<ProductBloc>().repository.getBusinessTypes();
      if (mounted) setState(() => businessTypes = List<BusinessTypeDto>.from(result));
    } catch (_) {
      businessTypes = [];
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    referenceOrderIdController.dispose();
    documentNumberController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
    if (pickedFile != null && mounted) setState(() => selectedImage = File(pickedFile.path));
  }

  List<ReferenceItem> getMoneyChannels() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      return state.references['moneyChannelTypes'] ?? const <ReferenceItem>[];
    }
    return const <ReferenceItem>[];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
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
                  onPressed: () => pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.translate('accounting.take_photo')),
                  onPressed: () => pickImage(ImageSource.camera),
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
              onChanged: (value) => setState(() => selectedMoneyChannel = value),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedBusinessTypeId,
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.revenue_business_type'),
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
              onChanged: (value) => setState(() => selectedBusinessTypeId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: referenceOrderIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.reference_order_id'),
                hintText: l10n.translate('accounting.reference_order_id_hint'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.translate('accounting.revenue_date')),
              subtitle: Text(DateFormatter.formatDate(selectedDate)),
              trailing: const Icon(Icons.lock),
              enabled: false,
              onTap: null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: documentNumberController,
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.document_number'),
                hintText: l10n.translate('accounting.document_number_hint'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : _closeDialog,
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed: isSubmitting
              ? null
              : () async {
                  setState(() => isSubmitting = true);
                  final amountString = amountController.text.replaceAll(',', '');
                  final amount = double.tryParse(amountString) ?? 0;
                  if (amount <= 0) {
                    setState(() => isSubmitting = false);
                    return;
                  }

                  if ((selectedMoneyChannel ?? '').trim().isEmpty) {
                    await AppDialog.show(
                      context,
                      title: l10n.translate('common.warning'),
                      message: l10n.translate('accounting.money_channel_required'),
                      type: AppDialogType.warning,
                    );
                    setState(() => isSubmitting = false);
                    return;
                  }

                  final ok = await widget.confirmAction(
                    title: l10n.translate('accounting.confirm_title'),
                    message: l10n.translate('accounting.confirm_create_revenue'),
                  );
                  if (!ok || !mounted) {
                    setState(() => isSubmitting = false);
                    return;
                  }

                  final allowed = await widget.checkFeatureAccess();
                  if (!allowed) {
                    setState(() => isSubmitting = false);
                    return;
                  }

                  if (!context.mounted) return;

                  final locationId = context.read<BusinessContext>().currentBusinessId;
                  final referenceOrderId = int.tryParse(referenceOrderIdController.text.trim());

                  context.read<RevenueBloc>().add(
                    CreateManualRevenueRequested(
                      body: {
                        'businessLocationId': int.tryParse(locationId ?? '') ?? 0,
                        'amount': amount,
                        'revenueDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                        if (selectedDocumentDate != null) 'documentDate': DateFormat('yyyy-MM-dd').format(selectedDocumentDate!),
                        if (documentNumberController.text.trim().isNotEmpty) 'documentNumber': documentNumberController.text.trim(),
                        'description': descriptionController.text,
                        'moneyChannel': selectedMoneyChannel,
                        if ((selectedBusinessTypeId ?? '').isNotEmpty) 'businessTypeId': selectedBusinessTypeId,
                        if (referenceOrderId != null) 'referenceType': 'order',
                        if (referenceOrderId != null) 'referenceId': referenceOrderId,
                      },
                      image: selectedImage,
                    ),
                  );
                  if (mounted) {
                    _closeDialog();
                  }
                },
          child: Text(l10n.translate('common.save')),
        ),
      ],
    );
  }
}
