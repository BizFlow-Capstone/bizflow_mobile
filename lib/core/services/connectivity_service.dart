import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  ConnectivityStatus _lastStatus = ConnectivityStatus.offline;

  ConnectivityStatus get lastStatus => _lastStatus;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.x returns a List. If any is not 'none', we are online.
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    final status = isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline;

    if (status != _lastStatus) {
      _lastStatus = status;
      _statusController.add(status);
      debugPrint('ConnectivityService: Status changed to $status');
    }
  }

  bool get isOnline => _lastStatus == ConnectivityStatus.online;
}
