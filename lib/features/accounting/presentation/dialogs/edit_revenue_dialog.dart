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
    final result =
        await context.read<ProductBloc>().repository.getBusinessTypes();
    businessTypes = List<BusinessTypeDto>.from(result);
  } catch (_) {
    businessTypes = [];
  }

  if (!context.mounted) return;

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
  var isSubmitting = false;

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
                  labelText:
                      l10n.translate('accounting.revenue_description'),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.translate('accounting.revenue_date')),
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
                    if (amount <= 0 ||
                        (selectedMoneyChannel ?? '').isEmpty) {
                      setDialogState(() => isSubmitting = false);
                      return;
                    }

                    final ok = await confirmAction(
                      title: l10n.translate('accounting.confirm_title'),
                      message: l10n.translate(
                        'accounting.confirm_update_revenue',
                      ),
                    );
                    if (!ok) {
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
                    context.read<RevenueBloc>().add(
                      UpdateManualRevenueRequested(
                        revenueId: item.id,
                        body: {
                          'businessLocationId':
                              int.tryParse(locationId ?? '') ??
                              item.locationId,
                          'amount': amount,
                          'revenueDate': DateFormat('yyyy-MM-dd')
                              .format(selectedDate),
                          'documentDate': selectedDocumentDate == null
                              ? null
                              : DateFormat('yyyy-MM-dd')
                                  .format(selectedDocumentDate!),
                          'description': descriptionController.text.trim(),
                          'moneyChannel': selectedMoneyChannel,
                          if ((selectedBusinessTypeId ?? '').isNotEmpty)
                            'businessTypeId': selectedBusinessTypeId,
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
