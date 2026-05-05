import 'dart:io';

import 'package:flutter/services.dart';

class AudioPublicStorageService {
  AudioPublicStorageService._();

  static const MethodChannel _channel = MethodChannel('bizflow/audio_storage');

  static Future<String?> saveToRecordings({
    required String sourcePath,
    String? displayName,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final savedPath = await _channel.invokeMethod<String>(
        'saveAudioToPublicRecordings',
        {
          'sourcePath': sourcePath,
          if ((displayName ?? '').trim().isNotEmpty) 'displayName': displayName,
        },
      );
      return savedPath;
    } catch (_) {
      return null;
    }
  }
}
