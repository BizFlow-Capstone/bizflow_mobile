import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../notification/notification_navigation_contract.dart';
import '../../features/auth/data/push_token_api_service.dart';
import '../notification/notification_service.dart';
import '../storage/secure_storage.dart';
import 'connectivity_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    'FirebaseMessagingService: background message received ${message.messageId}',
  );
}

class FirebaseMessagingService {
  static final StreamController<Map<String, dynamic>> _messageDataController =
      StreamController<Map<String, dynamic>>.broadcast();

  static final StreamController<String> _navigationController =
      StreamController<String>.broadcast();

  static Stream<Map<String, dynamic>> get messageDataStream =>
      _messageDataController.stream;

  static Stream<String> get navigationStream => _navigationController.stream;

  /// Route pending for navigation after auth
  static String? pendingRoute;

  static Future<String?> consumePendingRoute() async {
    if (pendingRoute != null && pendingRoute!.isNotEmpty) {
      final route = pendingRoute;
      pendingRoute = null;
      await SecureStorage().clearPendingNotificationAction();
      return route;
    }

    final storedRoute = await SecureStorage().getPendingNotificationAction();
    if (storedRoute != null && storedRoute.isNotEmpty) {
      await SecureStorage().clearPendingNotificationAction();
      return storedRoute;
    }

    return null;
  }

  final PushTokenApiService _pushTokenApiService;
  final NotificationService _notificationService;

  bool _initialized = false;
  bool _registrationSuccessful = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  FirebaseMessagingService({
    required PushTokenApiService pushTokenApiService,
    NotificationService? notificationService,
  }) : _pushTokenApiService = pushTokenApiService,
       _notificationService = notificationService ?? NotificationService();

  Future<void> initialize() async {
    if (_initialized) return;

    // Listen for connectivity changes to retry registration if it failed
    _connectivitySubscription = ConnectivityService().statusStream.listen((status) {
      if (status == ConnectivityStatus.online && !_registrationSuccessful) {
        debugPrint('FirebaseMessagingService: Network restored, retrying token registration...');
        unawaited(registerCurrentToken());
      }
    });

    final messaging = FirebaseMessaging.instance;

    await _notificationService.initialize();
    await _notificationService.requestPermission();

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get initial token but don't register yet (user not authenticated)
    _currentToken = await messaging.getToken();
    if (_currentToken != null && _currentToken!.isNotEmpty) {
      debugPrint(
        'FirebaseMessagingService.initialize: Token obtained: ${_currentToken!.substring(0, 20)}...',
      );
    }

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((
      newToken,
    ) async {
      final oldToken = _currentToken;
      _currentToken = newToken;

      debugPrint(
        'FirebaseMessagingService.onTokenRefresh: Old: ${oldToken?.substring(0, 20)}..., New: ${newToken.substring(0, 20)}...',
      );

      if (oldToken != null && oldToken.isNotEmpty && oldToken != newToken) {
        await _safeUnregister(oldToken);
      }

      await _safeRegister(newToken);
    });

    _onMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      final notification = message.notification;
      final title = notification?.title ?? 'BizFlow';
      final body = notification?.body ?? 'Bạn có thông báo mới';

      if (message.data.isNotEmpty) {
        _messageDataController.add(message.data);
      }

      // Pass route in payload for local notification tap handling
      final payload = _resolveRouteFromData(message.data);

      await _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: payload,
      );
    });

    // Handle notification click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FirebaseMessagingService: onMessageOpenedApp tap');
      unawaited(_handleMessageTap(message));
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FirebaseMessagingService: getInitialMessage tap');
      await _handleMessageTap(initialMessage);
    }

    _initialized = true;
  }

  static Future<void> setPendingRoute(
    String route, {
    bool persist = true,
  }) async {
    pendingRoute = route;
    _navigationController.add(route);
    if (persist) {
      await SecureStorage().savePendingNotificationAction(route);
    }
    debugPrint(
      'FirebaseMessagingService: Pending route set and emitted: $route',
    );
  }

  static Future<void> _handleMessageTap(RemoteMessage message) async {
    final route = _resolveRouteFromData(message.data);
    if (route == null) {
      return;
    }

    final hasAccessToken = await SecureStorage().hasAccessToken();
    if (hasAccessToken) {
      await setPendingRoute(route, persist: false);
    } else {
      pendingRoute = route;
      await SecureStorage().savePendingNotificationAction(route);
    }
  }

  static String? _resolveRouteFromData(Map<String, dynamic> data) {
    return NotificationNavigationContract.resolveFromPushData(data);
  }

  Future<void> registerCurrentToken({int maxRetries = 3}) async {
    try {
      // Re-fetch token from Firebase to ensure it's current and fresh
      final token =
          _currentToken ?? await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        debugPrint(
          'FirebaseMessagingService.registerCurrentToken: Token is null or empty',
        );
        return;
      }

      _currentToken = token;
      debugPrint(
        'FirebaseMessagingService.registerCurrentToken: Registering token ${token.substring(0, 20)}...',
      );

      // Retry logic with exponential backoff
      int attempt = 0;
      while (attempt < maxRetries) {
        final success = await _safeRegister(token);
        if (success) {
          _registrationSuccessful = true;
          return; // Success
        }

        attempt++;
        if (attempt < maxRetries) {
          final delayMs = 500 * (1 << (attempt - 1)); // 500ms, 1000ms, 2000ms
          debugPrint(
            'FirebaseMessagingService.registerCurrentToken: Retry $attempt/$maxRetries after ${delayMs}ms',
          );
          await Future.delayed(Duration(milliseconds: delayMs));
        } else {
          debugPrint(
            'FirebaseMessagingService.registerCurrentToken: Failed after $maxRetries attempts',
          );
        }
      }
    } catch (e) {
      debugPrint('FirebaseMessagingService.registerCurrentToken error: $e');
      // Don't throw, let app continue but log the error
    }
  }

  Future<void> unregisterCurrentToken() async {
    final token = _currentToken;
    if (token == null || token.isEmpty) return;
    await _safeUnregister(token);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _onMessageSubscription?.cancel();
  }

  Future<bool> _safeRegister(String token) async {
    try {
      await _pushTokenApiService.registerToken(token, platform: _platform);
      debugPrint(
        'FirebaseMessagingService._safeRegister: Successfully registered token ${token.substring(0, 20)}... on $_platform',
      );
      return true;
    } catch (e) {
      debugPrint('FirebaseMessagingService._safeRegister error: $e');
      return false;
    }
  }

  Future<void> _safeUnregister(String token) async {
    try {
      await _pushTokenApiService.unregisterToken(token);
      debugPrint(
        'FirebaseMessagingService._safeUnregister: Successfully unregistered token ${token.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('FirebaseMessagingService._safeUnregister error: $e');
    }
  }

  String get _platform {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }
}
