import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../storage/local_storage.dart';
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
      // Keep logout fast by switching away from scoped DB immediately.
      // Account-isolation is handled by per-user database files.
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
    if (token != null && token.trim().isNotEmpty) {
      final fromToken = _extractUserScopeFromToken(token);
      if (fromToken != null && fromToken.isNotEmpty) {
        return fromToken;
      }
    }

    // Fallback for tokens without stable subject claims.
    final storage = await LocalStorage.getInstance();
    final email = (storage.getString(StorageKeys.currentUserEmail) ?? '')
        .trim()
        .toLowerCase();
    if (email.isNotEmpty) {
      return 'email:$email';
    }

    final phone = (storage.getString(StorageKeys.currentUserPhone) ?? '').trim();
    if (phone.isNotEmpty) {
      return 'phone:$phone';
    }

    final ownerProfileId =
        (storage.getString(StorageKeys.currentOwnerProfileId) ?? '').trim();
    if (ownerProfileId.isNotEmpty) {
      return 'owner:$ownerProfileId';
    }

    return null;
  }

  String? _extractUserScopeFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      const candidateKeys = <String>[
        'profileId',
        'profile_id',
        'userId',
        'user_id',
        'sub',
        'nameid',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      ];

      for (final key in candidateKeys) {
        final raw = decoded[key]?.toString().trim();
        if (raw != null && raw.isNotEmpty) {
          return raw;
        }
      }

      return null;
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
