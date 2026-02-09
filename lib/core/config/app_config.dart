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
  static const String _hostDeviceIp = '192.168.1.16';    // Physical device IP
  static const String _hostEmulatorIp = '10.0.2.2';      // Emulator gateway
  
  // CHANGE THIS TO SWITCH BETWEEN DEVICE & EMULATOR
  static const bool _runningOnPhysicalDevice = true;     // Set to false for emulator

  static String get baseUrl {
    final host = _runningOnPhysicalDevice ? _hostDeviceIp : _hostEmulatorIp;
    
    switch (environment) {
      case 'production':
        return 'https://api.bizflow.com';
      case 'staging':
        return 'https://staging-api.bizflow.com';
      default:
        // Development - HTTP for both physical device & emulator
        // Backend: http://0.0.0.0:7270
        return 'http://$host:7270';
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
