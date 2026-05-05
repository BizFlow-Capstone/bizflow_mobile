import 'dart:async';

import 'package:flutter/foundation.dart';

class SyncStatusState {
  final bool isSyncing;
  final DateTime? lastUpdatedAt;
  final bool hasError;

  const SyncStatusState({
    required this.isSyncing,
    this.lastUpdatedAt,
    this.hasError = false,
  });
}

class SyncStatusController extends ChangeNotifier {
  static final SyncStatusController _instance =
      SyncStatusController._internal();
  factory SyncStatusController() => _instance;
  SyncStatusController._internal();

  int _activeRequests = 0;
  SyncStatusState _state = const SyncStatusState(isSyncing: false);

  /// Callback registered by the current screen to trigger a full data refresh.
  VoidCallback? _manualRefreshCallback;
  static const Duration _manualRefreshCooldown = Duration(seconds: 3);
  DateTime? _lastManualRefreshAt;
  Timer? _manualRefreshCooldownTimer;

  /// Whether a manual refresh callback is currently registered.
  bool get hasManualRefreshCallback => _manualRefreshCallback != null;

  bool get isManualRefreshCoolingDown {
    final last = _lastManualRefreshAt;
    if (last == null) {
      return false;
    }
    return DateTime.now().difference(last) < _manualRefreshCooldown;
  }

  /// Register a callback that will be called when the user taps the refresh button.
  void setManualRefreshCallback(VoidCallback? callback) {
    final hasChanged = _manualRefreshCallback != callback;
    _manualRefreshCallback = callback;
    if (hasChanged) {
      notifyListeners();
    }
  }

  /// Called by the refresh button in [AppSyncStatusText] to trigger a reload.
  void triggerManualRefresh() {
    if (_manualRefreshCallback == null || isManualRefreshCoolingDown) {
      return;
    }

    _lastManualRefreshAt = DateTime.now();
    _manualRefreshCooldownTimer?.cancel();
    _manualRefreshCooldownTimer = Timer(_manualRefreshCooldown, () {
      notifyListeners();
    });
    notifyListeners();

    _manualRefreshCallback?.call();
  }

  SyncStatusState get state => _state;

  void startSync() {
    _activeRequests += 1;
    if (!_state.isSyncing) {
      _state = SyncStatusState(
        isSyncing: true,
        lastUpdatedAt: _state.lastUpdatedAt,
        hasError: false,
      );
      notifyListeners();
    }
  }

  void endSync({DateTime? updatedAt, bool hasError = false}) {
    if (_activeRequests > 0) {
      _activeRequests -= 1;
    }

    if (_activeRequests == 0) {
      _state = SyncStatusState(
        isSyncing: false,
        lastUpdatedAt: updatedAt ?? DateTime.now(),
        hasError: hasError,
      );
      notifyListeners();
    }
  }

  /// Clear stale error state (for example when entering a new screen)
  /// while preserving the latest update timestamp.
  void clearError() {
    if (_state.hasError && !_state.isSyncing) {
      _state = SyncStatusState(
        isSyncing: false,
        lastUpdatedAt: _state.lastUpdatedAt,
        hasError: false,
      );
      notifyListeners();
    }
  }

  void reset() {
    _activeRequests = 0;
    _state = const SyncStatusState(isSyncing: false, hasError: false);
    _lastManualRefreshAt = null;
    _manualRefreshCooldownTimer?.cancel();
    _manualRefreshCooldownTimer = null;
    notifyListeners();
  }
}
