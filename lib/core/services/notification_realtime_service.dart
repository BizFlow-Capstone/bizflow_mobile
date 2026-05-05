import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'connectivity_service.dart';
import 'signalr_dev_http_client.dart';

class NotificationRealtimeService {
  static final NotificationRealtimeService _instance =
      NotificationRealtimeService._internal();

  factory NotificationRealtimeService() => _instance;

  NotificationRealtimeService._internal();

  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  final SecureStorage _secureStorage = SecureStorage();

  HubConnection? _hubConnection;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  bool get _isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  Future<void> initialize() async {
    _connectivitySubscription = ConnectivityService().statusStream.listen((status) {
      if (status == ConnectivityStatus.online && !_isConnected) {
        debugPrint('NotificationRealtimeService: Network restored, retrying connection...');
        unawaited(connect());
      }
    });
  }

  Future<void> connect() async {
    if (_isConnected) {
      return;
    }

    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final hubUrls = _resolveHubUrls(AppConfig.baseUrl);
    debugPrint(
      'NotificationRealtimeService: trying hub urls ${hubUrls.join(' | ')}',
    );

    for (final hubUrl in hubUrls) {
      try {
        final hubUri = Uri.parse(hubUrl);
        final isLocalHttps =
            hubUri.scheme == 'https' && _isLocalAddress(hubUri.host);

        final connection = HubConnectionBuilder()
            .withUrl(
              hubUrl,
              options: HttpConnectionOptions(
                accessTokenFactory: () async {
                  return await _secureStorage.getAccessToken() ?? '';
                },
                requestTimeout: 8000,
                transport: isLocalHttps ? HttpTransportType.LongPolling : null,
                httpClient: isLocalHttps ? SignalRDevHttpClient() : null,
              ),
            )
            .withAutomaticReconnect()
            .build();

        connection.on('notification.received', _handleNotificationReceived);
        connection.onclose(({Exception? error}) {
          debugPrint(
            'NotificationRealtimeService: connection closed ${error ?? ''}'
                .trim(),
          );
        });
        connection.onreconnected(({String? connectionId}) {
          debugPrint('NotificationRealtimeService: reconnected $connectionId');
        });
        connection.onreconnecting(({Exception? error}) {
          debugPrint(
            'NotificationRealtimeService: reconnecting ${error ?? ''}'.trim(),
          );
        });

        final startFuture = connection.start();
        if (startFuture == null) {
          throw Exception('SignalR start returned null future.');
        }
        await startFuture.timeout(const Duration(seconds: 8));
        _hubConnection = connection;
        debugPrint('NotificationRealtimeService: Connected to $hubUrl');
        return;
      } catch (error) {
        debugPrint(
          'NotificationRealtimeService.connect failed at $hubUrl: $error',
        );
      }
    }

    _hubConnection = null;
  }

  Future<void> disconnect() async {
    if (_hubConnection == null) {
      return;
    }

    try {
      await _hubConnection?.stop();
    } catch (_) {
      // Ignore disconnect errors.
    } finally {
      _hubConnection = null;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await disconnect();
  }

  void _handleNotificationReceived(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final raw = arguments.first;
    if (raw is Map<String, dynamic>) {
      _notificationController.add(raw);
      return;
    }

    if (raw is Map) {
      final mapped = <String, dynamic>{};
      raw.forEach((key, value) {
        mapped[key.toString()] = value;
      });
      _notificationController.add(mapped);
      return;
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final mapped = <String, dynamic>{};
          decoded.forEach((key, value) {
            mapped[key.toString()] = value;
          });
          _notificationController.add(mapped);
        }
      } catch (_) {
        // Ignore invalid payload format.
      }
    }
  }

  List<String> _resolveHubUrls(String baseUrl) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse(base);
    final urls = <String>['$base/hubs/notifications'];

    if (_isLocalAddress(uri.host)) {
      if (uri.scheme == 'https') {
        if (uri.hasPort) {
          urls.add('http://${uri.host}:${uri.port}/hubs/notifications');

          final companionHttpPort = _resolveCompanionHttpPort(uri.port);
          if (companionHttpPort != null) {
            urls.add(
              'http://${uri.host}:$companionHttpPort/hubs/notifications',
            );
          }
        }
      }

      urls.add('http://${uri.host}:8080/hubs/notifications');
      urls.add('http://${uri.host}:5139/hubs/notifications');
    }

    return urls.toSet().toList();
  }

  int? _resolveCompanionHttpPort(int httpsPort) {
    if (httpsPort == 7271) {
      return 5139;
    }

    if (httpsPort == 44338) {
      return 38453;
    }

    return null;
  }

  bool _isLocalAddress(String host) {
    return host == 'localhost' ||
        host == '10.0.2.2' ||
        host.startsWith('192.168.');
  }
}
