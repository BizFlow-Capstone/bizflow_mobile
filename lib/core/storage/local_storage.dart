import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local Storage Service - Quản lý SharedPreferences
class LocalStorage {
  static LocalStorage? _instance;
  static SharedPreferences? _prefs;

  LocalStorage._();

  static Future<LocalStorage> getInstance() async {
    _instance ??= LocalStorage._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // String
  Future<bool> setString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs!.getString(key);
  }

  // Int
  Future<bool> setInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs!.getInt(key);
  }

  // Double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs!.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs!.getDouble(key);
  }

  // Bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs!.getBool(key);
  }

  // String List
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs!.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs!.getStringList(key);
  }

  // Object (JSON)
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    return await _prefs!.setString(key, jsonString);
  }

  Map<String, dynamic>? getObject(String key) {
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('LocalStorage: Error parsing JSON for key $key: $e');
      return null;
    }
  }

  // Remove
  Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }

  // Clear all
  Future<bool> clear() async {
    return await _prefs!.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _prefs!.getKeys();
  }
}

/// Storage Keys - Tập trung quản lý keys
class StorageKeys {
  StorageKeys._();

  // Auth
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userProfile = 'user_profile';

  // Settings
  static const String locale = 'locale';
  static const String themeMode = 'theme_mode';
  static const String isFirstLaunch = 'is_first_launch';
  static const String notificationEnabled = 'notification_enabled';

  // Cache
  static const String lastSyncTime = 'last_sync_time';

  // Add more keys here...
}
