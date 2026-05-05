import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../cost/presentation/bloc/cost_bloc.dart';

Future<void> showAddCostDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final refState = context.read<ReferenceBloc>().state;
  if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
    context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
  }

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final documentNumberController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDocumentDate;
  String? selectedCostType;
  String? selectedPaymentMethod;
  File? selectedImage;
  var isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source, void Function(void Function()) setDialogState) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
    if (pickedFile != null) {
      setDialogState(() => selectedImage = File(pickedFile.path));
    }
  }

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

  await showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        title: Text(l10n.translate('accounting.add_cost')),
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
                initialValue: selectedCostType,
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.ai_cost_type'),
                ),
                items: getCostTypes()
                    .where((c) => c.code.toLowerCase() != 'import' && c.label.trim().isNotEmpty)
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.code,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedCostType = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.ai_payment_method'),
                ),
                items: getPaymentMethods()
                    .where((item) => item.label.trim().isNotEmpty)
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.code,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedPaymentMethod = value),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.translate('accounting.cost_date')),
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
                    if (descriptionController.text.trim().isEmpty ||
                        amount <= 0 ||
                        selectedCostType == null ||
                        selectedPaymentMethod == null) {
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    final locationId =
                        context.read<BusinessContext>().currentBusinessId;
                    context.read<CostBloc>().add(
                      CreateManualCostRequested(
                        body: {
                          'businessLocationId': int.tryParse(locationId ?? '') ?? 0,
                          'amount': amount,
                          'costDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                          if (selectedDocumentDate != null)
                            'documentDate': DateFormat('yyyy-MM-dd').format(selectedDocumentDate!),
                          if (documentNumberController.text.trim().isNotEmpty)
                            'documentNumber': documentNumberController.text.trim(),
                          'description': descriptionController.text,
                          'costType': selectedCostType,
                          'paymentMethod': selectedPaymentMethod,
                        },
                        image: selectedImage,
                      ),
                    );
                    Navigator.pop(dialogCtx);
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
