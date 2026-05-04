import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import 'document_number_service.dart';

/// Shows a duplicate-document-number warning dialog if needed.
/// Returns `true` if the user can proceed (no duplicate, or user chose Continue).
/// Returns `false` if the user cancelled.
///
/// [documentNumber]  — the value entered by the user. If null/empty, always returns true.
/// [excludeCostId]   — pass when editing an existing cost to avoid self-match.
/// [excludeRevenueId] — pass when editing an existing revenue to avoid self-match.
Future<bool> checkDocumentNumberAndConfirm(
  BuildContext context, {
  required String? documentNumber,
  int? excludeCostId,
  int? excludeRevenueId,
}) async {
  final trimmed = (documentNumber ?? '').trim();
  if (trimmed.isEmpty) return true; // nothing to check

  final service = context.read<DocumentNumberService>();
  final l10n = AppLocalizations.of(context);

  final exists = await service.checkExists(
    documentNumber: trimmed,
    excludeCostId: excludeCostId,
    excludeRevenueId: excludeRevenueId,
  );

  if (!exists) return true; // no duplicate

  if (!context.mounted) return false;

  // Show blocking warning dialog
  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(l10n.translate('document_number.duplicate_title')),
      content: Text(
        l10n
            .translate('document_number.duplicate_message')
            .replaceAll('{number}', trimmed),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text(l10n.translate('common.ok') ?? 'OK'),
        ),
      ],
    ),
  );

  return false; // User must adjust the document number and try again
}
