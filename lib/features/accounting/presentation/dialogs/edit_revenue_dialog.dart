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
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../product/data/models/business_type_model.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../revenue/domain/entities/revenue_entity.dart';
import '../../../revenue/presentation/bloc/revenue_bloc.dart';

Future<void> showEditRevenueDialog({
  required BuildContext context,
  required RevenueEntity item,
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
    builder: (_) => _EditRevenueDialog(
      item: item,
      confirmAction: confirmAction,
      checkFeatureAccess: checkFeatureAccess,
    ),
  );
}

class _EditRevenueDialog extends StatefulWidget {
  const _EditRevenueDialog({required this.item, required this.confirmAction, required this.checkFeatureAccess});

  final RevenueEntity item;
  final Future<bool> Function({required String title, required String message}) confirmAction;
  final Future<bool> Function() checkFeatureAccess;

  @override
  State<_EditRevenueDialog> createState() => _EditRevenueDialogState();
}

class _EditRevenueDialogState extends State<_EditRevenueDialog> {
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  late final TextEditingController documentNumberController;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDocumentDate;
  String? selectedMoneyChannel;
  List<BusinessTypeDto> businessTypes = [];
  String? selectedBusinessTypeId;
  File? selectedImage;
  bool isSubmitting = false;
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
    amountController = TextEditingController(text: CurrencyFormatter.formatNumber(widget.item.amount));
    descriptionController = TextEditingController(text: widget.item.description);
    documentNumberController = TextEditingController(text: widget.item.documentNumber ?? '');
    selectedDocumentDate = widget.item.documentDate;
    selectedMoneyChannel = widget.item.moneyChannel;
    selectedBusinessTypeId = widget.item.businessTypeId;
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
    final channels = getMoneyChannels();
    final businessTypeIds = businessTypes.map((e) => e.businessTypeId).toSet();
    final effectiveMoneyChannel = channels.any((c) => c.code == selectedMoneyChannel) ? selectedMoneyChannel : null;
    final effectiveBusinessTypeId = businessTypeIds.contains(selectedBusinessTypeId) ? selectedBusinessTypeId : null;

    return AlertDialog(
      title: Text(l10n.translate('accounting.edit_revenue')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: AppInputFormatters.withSqlInjectionGuard(inputFormatters: [CurrencyInputFormatter()]),
              decoration: InputDecoration(labelText: l10n.translate('accounting.revenue_amount')),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: l10n.translate('accounting.revenue_description'))),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              ElevatedButton.icon(icon: const Icon(Icons.photo_library), label: Text(l10n.translate('accounting.select_image')), onPressed: () => pickImage(ImageSource.gallery)),
              const SizedBox(width: 8),
              ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: Text(l10n.translate('accounting.take_photo')), onPressed: () => pickImage(ImageSource.camera)),
            ]),
            if (selectedImage != null) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(selectedImage!, height: 120, fit: BoxFit.cover)),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: effectiveMoneyChannel,
              decoration: InputDecoration(labelText: l10n.translate('accounting.channel')),
              items: getMoneyChannels().where((item) => item.label.trim().isNotEmpty).map((item) => DropdownMenuItem<String>(value: item.code, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => selectedMoneyChannel = value),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: effectiveBusinessTypeId,
              decoration: InputDecoration(labelText: l10n.translate('accounting.revenue_business_type')),
              items: businessTypes.map((type) => DropdownMenuItem<String>(value: type.businessTypeId, child: Text(type.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) => setState(() => selectedBusinessTypeId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.translate('accounting.revenue_date')), subtitle: Text(DateFormatter.formatDate(selectedDate)), trailing: const Icon(Icons.lock), enabled: false, onTap: null),
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
                  if (amount <= 0 || (selectedMoneyChannel ?? '').isEmpty) {
                    setState(() => isSubmitting = false);
                    return;
                  }

                  final ok = await widget.confirmAction(title: l10n.translate('accounting.confirm_title'), message: l10n.translate('accounting.confirm_update_revenue'));
                  if (!mounted) return;
                  if (!ok) {
                    if (mounted) setState(() => isSubmitting = false);
                    return;
                  }

                  final allowed = await widget.checkFeatureAccess();
                  if (!mounted) return;
                  if (!allowed) {
                    if (mounted) setState(() => isSubmitting = false);
                    return;
                  }

                  if (!context.mounted) return;

                  final locationId = context.read<BusinessContext>().currentBusinessId;
                  context.read<RevenueBloc>().add(
                    UpdateManualRevenueRequested(
                      revenueId: widget.item.id,
                      body: {
                        'businessLocationId': int.tryParse(locationId ?? '') ?? widget.item.locationId,
                        'amount': amount,
                        'revenueDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'documentDate': selectedDocumentDate == null ? null : DateFormat('yyyy-MM-dd').format(selectedDocumentDate!),
                        if (documentNumberController.text.trim().isNotEmpty) 'documentNumber': documentNumberController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'moneyChannel': selectedMoneyChannel,
                        if ((selectedBusinessTypeId ?? '').isNotEmpty) 'businessTypeId': selectedBusinessTypeId,
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

