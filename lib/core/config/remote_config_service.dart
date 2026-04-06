import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Remote Config Service - Feature flags & remote configuration
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  bool _isInitialized = false;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Default values
  final Map<String, dynamic> _defaults = {
    // Feature flags
    'feature_new_home': false,
    'feature_dark_mode': true,
    'feature_biometric_login': true,
    'feature_push_notification': true,

    // Config values
    'min_app_version': '1.0.0',
    'maintenance_mode': false,
    'maintenance_message': '',
    'force_update': false,
    'max_upload_size_mb': 10,
  };

  // Cached values used as safe fallback if fetch/read fails.
  final Map<String, dynamic> _values = {};

  /// Initialize remote config
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _remoteConfig.setDefaults(_defaults);
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Keep defaults as local fallback for resilience.
    _values
      ..clear()
      ..addAll(_defaults);

    _isInitialized = true;
    debugPrint('RemoteConfigService: Initialized');
  }

  /// Fetch and activate
  Future<bool> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();

      debugPrint('RemoteConfigService: Fetched and activated');
      return true;
    } catch (e) {
      debugPrint('RemoteConfigService: Error fetching - $e');
      return false;
    }
  }

  /// Get bool value
  bool getBool(String key) {
    if (_isInitialized) {
      try {
        return _remoteConfig.getBool(key);
      } catch (_) {
        // Fall through to local defaults.
      }
    }
    return _values[key] as bool? ?? _defaults[key] as bool? ?? false;
  }

  /// Get string value
  String getString(String key) {
    if (_isInitialized) {
      try {
        return _remoteConfig.getString(key);
      } catch (_) {
        // Fall through to local defaults.
      }
    }
    return _values[key] as String? ?? _defaults[key] as String? ?? '';
  }

  /// Get int value
  int getInt(String key) {
    if (_isInitialized) {
      try {
        return _remoteConfig.getInt(key);
      } catch (_) {
        // Fall through to local defaults.
      }
    }
    return _values[key] as int? ?? _defaults[key] as int? ?? 0;
  }

  /// Get double value
  double getDouble(String key) {
    if (_isInitialized) {
      try {
        return _remoteConfig.getDouble(key);
      } catch (_) {
        // Fall through to local defaults.
      }
    }
    return (_values[key] as num?)?.toDouble() ??
        (_defaults[key] as num?)?.toDouble() ??
        0.0;
  }

  // Feature flags shortcuts
  bool get isNewHomeEnabled => getBool('feature_new_home');
  bool get isDarkModeEnabled => getBool('feature_dark_mode');
  bool get isBiometricLoginEnabled => getBool('feature_biometric_login');
  bool get isPushNotificationEnabled => getBool('feature_push_notification');

  // Config shortcuts
  String get minAppVersion => getString('min_app_version');
  bool get isMaintenanceMode => getBool('maintenance_mode');
  String get maintenanceMessage => getString('maintenance_message');
  bool get isForceUpdate => getBool('force_update');
  int get maxUploadSizeMb => getInt('max_upload_size_mb');
}

/// Remote Config Keys
class RemoteConfigKeys {
  RemoteConfigKeys._();

  // Feature flags
  static const String featureNewHome = 'feature_new_home';
  static const String featureDarkMode = 'feature_dark_mode';
  static const String featureBiometricLogin = 'feature_biometric_login';
  static const String featurePushNotification = 'feature_push_notification';

  // Config values
  static const String minAppVersion = 'min_app_version';
  static const String maintenanceMode = 'maintenance_mode';
  static const String maintenanceMessage = 'maintenance_message';
  static const String forceUpdate = 'force_update';
  static const String maxUploadSizeMb = 'max_upload_size_mb';
}
