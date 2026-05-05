/// App Configuration
class AppConfig {
  AppConfig._();

  // Environment
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // API Configuration
  // Choose based on what you're testing on:
  //
  //  PHYSICAL DEVICE (RFCTB0VPSSR):
  //    - Use your host machine IP from: ipconfig
  //    - Example: 192.168.1.16
  //    - Protocol: HTTP (simpler for development)
  //
  //  ANDROID EMULATOR:
  //    - Use 10.0.2.2 (Android gateway to host)
  //    - Protocol: HTTP (avoid HTTPS complexity)
  //
  static const String _hostDeviceIp = String.fromEnvironment(
    'API_HOST_DEVICE',
    defaultValue: '192.168.1.197',
  );
  static const String _hostEmulatorIp = String.fromEnvironment(
    'API_HOST_EMULATOR',
    defaultValue: '10.0.2.2',
  );
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // CHANGE THIS TO SWITCH BETWEEN DEVICE & EMULATOR
  static const bool _runningOnPhysicalDevice = bool.fromEnvironment(
    'RUN_ON_PHYSICAL_DEVICE',
    defaultValue: true,
  );

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    final host = _runningOnPhysicalDevice ? _hostDeviceIp : _hostEmulatorIp;

    switch (environment) {
      case 'production':
        return 'https://api.bizflow.asia';
      case 'staging':
        return 'https://staging-api.bizflow.com';
      default:
        // Development (Docker): API is exposed at http://<host>:8080
        return 'http://$host:8080';
    }
  }

  // Timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);

  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;

  // App Info
  static const String appName = 'BizFlow';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Debug
  static bool get enableLogging => !isProduction;
  static bool get enableCrashlytics => isProduction || isStaging;
}
