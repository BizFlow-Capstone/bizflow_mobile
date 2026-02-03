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

  // API
  static String get baseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.bizflow.com';
      case 'staging':
        return 'https://staging-api.bizflow.com';
      default:
        // Android emulator: Use 10.0.2.2 (not localhost)
        // HTTPS - Backend đang force HTTPS
        // Note: Cần trust self-signed certificate
        return 'https://10.0.2.2:7270';
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
