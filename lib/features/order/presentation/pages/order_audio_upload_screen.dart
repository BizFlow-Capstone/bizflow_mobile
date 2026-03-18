import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import 'package:file_picker/file_picker.dart';
import 'order_form_screen.dart';

class OrderAudioUploadScreen extends StatefulWidget {
  const OrderAudioUploadScreen({super.key});

  @override
  State<OrderAudioUploadScreen> createState() => _OrderAudioUploadScreenState();
}

class _OrderAudioUploadScreenState extends State<OrderAudioUploadScreen> {
  String? _selectedFileName;

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
      });
      // Simulate processing
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderFormScreen(inputType: 'audio'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.audio_upload_title')),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.translate('order_create.audio_upload_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_selectedFileName != null)
                  Text(
                    _selectedFileName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickAudioFile,
                    icon: const Icon(Icons.audio_file),
                    label: Text(
                      l10n.translate('order_create.audio_upload_btn'),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
