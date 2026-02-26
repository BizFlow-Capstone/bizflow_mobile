import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'order_form_screen.dart';

class OrderVoiceRecordScreen extends StatefulWidget {
  const OrderVoiceRecordScreen({Key? key}) : super(key: key);

  @override
  State<OrderVoiceRecordScreen> createState() => _OrderVoiceRecordScreenState();
}

class _OrderVoiceRecordScreenState extends State<OrderVoiceRecordScreen> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String _transcribedText = "";

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _transcribedText =
            "Anh cho em 1 điện thoại iphone 15 và 1 ốp lưng..."; // Mock transcription
      });

      // Simulate AI processing
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderFormScreen(inputType: 'voice'),
        ),
      );
    } else {
      var status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}/order_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() {
            _isRecording = true;
            _transcribedText = "Đang nghe...";
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.voice_record_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.translate('order_create.voice_text_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _transcribedText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording
                      ? l10n.translate('order_create.voice_stop_btn')
                      : l10n.translate('order_create.voice_record_btn'),
                  style: TextStyle(
                    color: _isRecording ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
