import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../core/localization/app_localizations.dart';

/// A wrapper around SimpleBarcodeScanner platform view
/// This replaces the deprecated SimpleBarcodeScannerPage and
/// ensures the scanner is constrained within Flutter's SafeArea.
class AppBarcodeScanner extends StatelessWidget {
  const AppBarcodeScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.translate('product.scan_barcode')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SimpleBarcodeScanner(
          onBarcodeViewCreated: (controller) {
            // Needed by SimpleBarcodeScanner
          },
          onScanned: (res) {
            if (context.mounted) {
              Navigator.pop(context, res);
            }
          },
        ),
      ),
    );
  }
}
