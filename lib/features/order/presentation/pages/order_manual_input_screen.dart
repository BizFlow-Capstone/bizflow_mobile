import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import 'order_form_screen.dart';

class OrderManualInputScreen extends StatelessWidget {
  const OrderManualInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.manual_input_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.black,
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                l10n.translate('order_create.manual_input_title'),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const OrderFormScreen(inputType: 'manual'),
                    ),
                  );
                },
                child: const Text('Tiếp tục đến form đơn hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
