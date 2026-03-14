import 'package:flutter/foundation.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service - Quản lý lưu trữ bảo mật
/// Dùng cho token, password, sensitive data
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  // TODO: Uncomment khi thêm package flutter_secure_storage
  // final FlutterSecureStorage _storage = const FlutterSecureStorage(
  //   aOptions: AndroidOptions(
  //     encryptedSharedPreferences: true,
  //   ),
  //   iOptions: IOSOptions(
  //     accessibility: KeychainAccessibility.first_unlock_this_device,
  //   ),
  // );

  // Tạm thời dùng Map để lưu (chỉ trong memory - không bảo mật)
  // Khi production, thay bằng flutter_secure_storage
  final Map<String, String> _tempStorage = {};

  /// Write value
  Future<void> write({required String key, required String value}) async {
    // TODO: await _storage.write(key: key, value: value);
    _tempStorage[key] = value;
    debugPrint('SecureStorage: Write key=$key');
  }

  /// Read value
  Future<String?> read({required String key}) async {
    // TODO: return await _storage.read(key: key);
    debugPrint('SecureStorage: Read key=$key');
    return _tempStorage[key];
  }

  /// Delete value
  Future<void> delete({required String key}) async {
    // TODO: await _storage.delete(key: key);
    _tempStorage.remove(key);
    debugPrint('SecureStorage: Delete key=$key');
  }

  /// Delete all
  Future<void> deleteAll() async {
    // TODO: await _storage.deleteAll();
    _tempStorage.clear();
    debugPrint('SecureStorage: Delete all');
  }

  /// Check if key exists
  Future<bool> containsKey({required String key}) async {
    // TODO: return await _storage.containsKey(key: key);
    return _tempStorage.containsKey(key);
  }

  /// Read all
  Future<Map<String, String>> readAll() async {
    // TODO: return await _storage.readAll();
    return Map.from(_tempStorage);
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
