import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service - Quản lý lưu trữ bảo mật
/// Dùng cho token, password, sensitive data
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Write value
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
    debugPrint('SecureStorage: Write key=$key');
  }

  /// Read value
  Future<String?> read({required String key}) async {
    debugPrint('SecureStorage: Read key=$key');
    return _storage.read(key: key);
  }

  /// Delete value
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
    debugPrint('SecureStorage: Delete key=$key');
  }

  /// Delete all
  Future<void> deleteAll() async {
    await _storage.deleteAll();
    debugPrint('SecureStorage: Delete all');
  }

  /// Check if key exists
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: key);
  }

  /// Read all
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }
}

/// Secure Storage Keys
class SecureStorageKeys {
  SecureStorageKeys._();

  static const String accessToken = 'secure_access_token';
  static const String refreshToken = 'secure_refresh_token';
  static const String pinCode = 'pin_code';
  static const String biometricKey = 'biometric_key';
}

/// Token management helpers
extension SecureStorageTokenExtension on SecureStorage {
  /// Save both access and refresh tokens
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await write(key: SecureStorageKeys.accessToken, value: accessToken);
    await write(key: SecureStorageKeys.refreshToken, value: refreshToken);
  }

  /// Get stored access token
  Future<String?> getAccessToken() {
    return read(key: SecureStorageKeys.accessToken);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() {
    return read(key: SecureStorageKeys.refreshToken);
  }

  /// Clear all auth tokens (on logout)
  Future<void> clearAuthTokens() async {
    await delete(key: SecureStorageKeys.accessToken);
    await delete(key: SecureStorageKeys.refreshToken);
  }

  /// Check if user has a stored access token
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
