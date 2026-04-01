import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import 'app_database.dart';

class DatabaseManager {
  DatabaseManager._internal();

  static final DatabaseManager _instance = DatabaseManager._internal();

  factory DatabaseManager() => _instance;

  final SecureStorage _secureStorage = SecureStorage();
  Future<void> _queue = Future<void>.value();

  Future<void> initialize() {
    return _serialize(() async {
      final userScope = await _resolveCurrentUserScope();
      await AppDatabase.reconfigureForUserScope(userScope);
      await _verifyWalMode('initialize');
    });
  }

  Future<void> switchToUserScope(String? userScope) {
    return _serialize(() async {
      await AppDatabase.reconfigureForUserScope(userScope);
      await _verifyWalMode('switchToUserScope');
    });
  }

  Future<void> clearForLogout() {
    return _serialize(() async {
      await AppDatabase().clearUserScopedData();
      await AppDatabase.reconfigureForUserScope(null);
      await _verifyWalMode('clearForLogout');
    });
  }

  Future<T> runAtomic<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _serialize(Future<void> Function() action) {
    _queue = _queue.then((_) => action());
    return _queue;
  }

  Future<String?> _resolveCurrentUserScope() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      return decoded['profileId']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _verifyWalMode(String source) async {
    final ok = await AppDatabase().verifyWalMode();
    if (!ok) {
      debugPrint('DatabaseManager: WAL verification failed at $source');
    }
  }
}
