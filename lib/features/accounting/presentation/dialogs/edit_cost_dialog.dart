import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../shared/context/business_context.dart';
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
  var isSubmitting = false;

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
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.ai_cost_type'),
                ),
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
                decoration: InputDecoration(
                  labelText: l10n.translate('accounting.ai_payment_method'),
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
                title: Text(l10n.translate('accounting.cost_date')),
                subtitle:
                    Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
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
                      : DateFormat('yyyy-MM-dd').format(selectedDocumentDate!),
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

                    final ok = await confirmAction(
                      title: l10n.translate('accounting.confirm_title'),
                      message:
                          l10n.translate('accounting.confirm_update_item'),
                    );
                    if (!ok) {
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    if (!dialogCtx.mounted) return;

                    context.read<CostBloc>().add(
                      UpdateManualCostRequested(
                        costId: item.id,
                        body: {
                          'amount': amount,
                          'costDate':
                              DateFormat('yyyy-MM-dd').format(selectedDate),
                          'documentDate': selectedDocumentDate == null
                              ? null
                              : DateFormat('yyyy-MM-dd')
                                  .format(selectedDocumentDate!),
                          'description': descriptionController.text.trim(),
                          'costType': selectedCostType ?? item.type,
                          'paymentMethod':
                              selectedPaymentMethod ?? item.paymentMethod,
                          'removeDocument': false,
                        },
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
