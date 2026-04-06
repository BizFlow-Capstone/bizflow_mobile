import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM Message type
enum FcmMessageType { notification, data, both }

/// FCM Message model
class FcmMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final FcmMessageType type;

  FcmMessage({this.title, this.body, this.data, required this.type});

  factory FcmMessage.fromMap(Map<String, dynamic> map) {
    final notification = map['notification'] as Map<String, dynamic>?;
    final data = map['data'] as Map<String, dynamic>?;

    FcmMessageType type;
    if (notification != null && data != null) {
      type = FcmMessageType.both;
    } else if (notification != null) {
      type = FcmMessageType.notification;
    } else {
      type = FcmMessageType.data;
    }

    return FcmMessage(
      title: notification?['title'] as String?,
      body: notification?['body'] as String?,
      data: data,
      type: type,
    );
  }
}

/// FCM Handler - Quản lý Firebase Cloud Messaging
class FcmHandler {
  static final FcmHandler _instance = FcmHandler._internal();
  factory FcmHandler() => _instance;
  FcmHandler._internal();

  bool _isInitialized = false;
  String? _fcmToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Callback khi nhận message
  void Function(FcmMessage message)? onMessage;

  /// Callback khi nhấn vào notification
  void Function(FcmMessage message)? onMessageOpenedApp;

  /// Callback khi token thay đổi
  void Function(String token)? onTokenRefresh;

  /// Initialize FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    _fcmToken = await messaging.getToken();
    debugPrint('FcmHandler: Current FCM token: $_fcmToken');

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      onTokenRefresh?.call(token);
    });

    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      final fcmMessage = _fromRemoteMessage(message);
      onMessage?.call(fcmMessage);
    });

    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((message) {
          final fcmMessage = _fromRemoteMessage(message);
          onMessageOpenedApp?.call(fcmMessage);
        });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      final fcmMessage = _fromRemoteMessage(initialMessage);
      onMessageOpenedApp?.call(fcmMessage);
    }

    _isInitialized = true;
    debugPrint('FcmHandler: Initialized');
  }

  /// Handle incoming message
  void handleMessage(Map<String, dynamic> message) {
    debugPrint('FcmHandler: Received message - $message');

    final fcmMessage = FcmMessage.fromMap(message);
    onMessage?.call(fcmMessage);
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('FcmHandler: Subscribed to topic - $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('FcmHandler: Unsubscribed from topic - $topic');
  }

  /// Delete token
  Future<void> deleteToken() async {
    await FirebaseMessaging.instance.deleteToken();
    _fcmToken = null;
    debugPrint('FcmHandler: Token deleted');
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
  }

  FcmMessage _fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final hasNotification = notification != null;
    final hasData = message.data.isNotEmpty;

    final type = hasNotification && hasData
        ? FcmMessageType.both
        : hasNotification
        ? FcmMessageType.notification
        : FcmMessageType.data;

    return FcmMessage(
      title: notification?.title,
      body: notification?.body,
      data: hasData ? Map<String, dynamic>.from(message.data) : null,
      type: type,
    );
  }
}
