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
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../cost/domain/entities/cost_entity.dart';
import '../../../cost/presentation/bloc/cost_bloc.dart';

Future<void> showEditCostDialog({
  required BuildContext context,
  required CostEntity item,
  required Future<bool> Function({
    required String title,
    required String message,
  }) confirmAction,
}) async {
  final refState = context.read<ReferenceBloc>().state;
  if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
    context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
  }

  await showDialog(
    context: context,
    builder: (_) => _EditCostDialog(
      item: item,
      confirmAction: confirmAction,
    ),
  );
}

class _EditCostDialog extends StatefulWidget {
  const _EditCostDialog({required this.item, required this.confirmAction});

  final CostEntity item;
  final Future<bool> Function({required String title, required String message}) confirmAction;

  @override
  State<_EditCostDialog> createState() => _EditCostDialogState();
}

class _EditCostDialogState extends State<_EditCostDialog> {
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  late final TextEditingController documentNumberController;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDocumentDate;
  String? selectedCostType;
  String? selectedPaymentMethod;
  File? selectedImage;
  bool removeImage = false;
  bool isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  void _closeDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: CurrencyFormatter.formatNumber(widget.item.amount));
    descriptionController = TextEditingController(text: widget.item.description);
    documentNumberController = TextEditingController(text: widget.item.documentNumber ?? '');
    selectedDocumentDate = widget.item.documentDate;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    documentNumberController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
    if (pickedFile != null && mounted) setState(() { selectedImage = File(pickedFile.path); removeImage = false; });
  }

  List<ReferenceItem> getCostTypes() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      return (state.references['costTypes'] ?? const <ReferenceItem>[]).toSet().toList();
    }
    return const <ReferenceItem>[];
  }

  List<ReferenceItem> getPaymentMethods() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      return (state.references['paymentMethods'] ?? const <ReferenceItem>[]).toSet().toList();
    }
    return const <ReferenceItem>[];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final costTypes = getCostTypes();
    final paymentMethods = getPaymentMethods();
    final effectiveCostType = costTypes.any((item) => item.code == selectedCostType)
      ? selectedCostType
      : null;
    final effectivePaymentMethod = paymentMethods.any((item) => item.code == selectedPaymentMethod)
      ? selectedPaymentMethod
      : null;
    return AlertDialog(
      title: Text(l10n.translate('accounting.edit_cost')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.translate('accounting.description')),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: AppInputFormatters.withSqlInjectionGuard(inputFormatters: [CurrencyInputFormatter()]),
              decoration: InputDecoration(labelText: l10n.translate('accounting.amount')),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                ElevatedButton.icon(icon: const Icon(Icons.photo_library), label: Text(l10n.translate('accounting.select_image')), onPressed: () => pickImage(ImageSource.gallery)),
                const SizedBox(width: 8),
                ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: Text(l10n.translate('accounting.take_photo')), onPressed: () => pickImage(ImageSource.camera)),
                const SizedBox(width: 8),
                if (!removeImage && widget.item.documentUrl != null && widget.item.documentUrl!.isNotEmpty)
                  TextButton(onPressed: () => setState(() => removeImage = true), child: Text(l10n.translate('accounting.remove_image'))),
              ],
            ),
            if (selectedImage != null) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(selectedImage!, height: 120, fit: BoxFit.cover)),
            ] else if (!removeImage && widget.item.documentUrl != null && widget.item.documentUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.item.documentUrl!, height: 120, fit: BoxFit.cover)),
            ] else if (removeImage) ...[
              const SizedBox(height: 8),
              Text(l10n.translate('accounting.image_will_be_removed')),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: effectiveCostType,
              decoration: InputDecoration(labelText: l10n.translate('accounting.ai_cost_type')),
              items: costTypes.where((c) => c.code.toLowerCase() != 'import' && c.label.trim().isNotEmpty).map((item) => DropdownMenuItem<String>(value: item.code, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => selectedCostType = value),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: effectivePaymentMethod,
              decoration: InputDecoration(labelText: l10n.translate('accounting.ai_payment_method')),
              items: paymentMethods.where((item) => item.label.trim().isNotEmpty).map((item) => DropdownMenuItem<String>(value: item.code, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => selectedPaymentMethod = value),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.translate('accounting.cost_date')), subtitle: Text(DateFormatter.formatDate(selectedDate)), trailing: const Icon(Icons.lock), enabled: false, onTap: null),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: documentNumberController, decoration: InputDecoration(labelText: l10n.translate('accounting.document_number'), hintText: l10n.translate('accounting.document_number_hint'))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: isSubmitting ? null : _closeDialog, child: Text(l10n.translate('common.cancel'))),
        ElevatedButton(
          onPressed: isSubmitting
              ? null
              : () async {
                  setState(() => isSubmitting = true);
                  final amount = (CurrencyFormatter.parse(amountController.text) ?? 0).toDouble();
                  if (descriptionController.text.trim().isEmpty || amount <= 0 || selectedCostType == null || selectedPaymentMethod == null) {
                    setState(() => isSubmitting = false);
                    return;
                  }

                  final ok = await widget.confirmAction(title: l10n.translate('accounting.confirm_title'), message: l10n.translate('accounting.confirm_update_item'));
                  if (!mounted) return;
                  if (!ok) {
                    if (mounted) setState(() => isSubmitting = false);
                    return;
                  }

                  if (!context.mounted) return;

                  context.read<CostBloc>().add(
                        UpdateManualCostRequested(
                      costId: widget.item.id,
                      body: {
                        'amount': amount,
                        'costDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'documentDate': selectedDocumentDate == null ? null : DateFormat('yyyy-MM-dd').format(selectedDocumentDate!),
                        if (documentNumberController.text.trim().isNotEmpty) 'documentNumber': documentNumberController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'costType': selectedCostType ?? widget.item.type,
                        'paymentMethod': selectedPaymentMethod ?? widget.item.paymentMethod,
                        'removeDocument': removeImage,
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

