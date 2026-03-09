import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../core/localization/app_localizations.dart';

/// Opens the native full-screen barcode scanner.
///
/// Returns the scanned barcode string, or null if the user cancelled.
///
/// Usage:
/// ```dart
/// final barcode = await AppBarcodeScanner.scan(context);
/// if (barcode != null && barcode.isNotEmpty) { ... }
/// ```
class AppBarcodeScanner {
  AppBarcodeScanner._();

  static Future<String?> scan(
    BuildContext context, {
    ScanType scanType = ScanType.barcode,
  }) async {
    final l10n = AppLocalizations.of(context);
    final cancelText = l10n.translate('common.cancel');

    final result = await SimpleBarcodeScanner.scanBarcode(
      context,
      cancelButtonText: cancelText.isNotEmpty ? cancelText : 'Cancel',
      isShowFlashIcon: true,
      scanType: scanType,
    );

    // The native scanner returns '-1' when the user cancels
    if (result == null || result == '-1' || result.isEmpty) return null;
    return result;
  }
}
