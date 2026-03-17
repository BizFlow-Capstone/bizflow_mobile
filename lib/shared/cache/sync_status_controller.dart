import 'package:flutter/foundation.dart';

class SyncStatusState {
  final bool isSyncing;
  final DateTime? lastUpdatedAt;

  const SyncStatusState({
    required this.isSyncing,
    this.lastUpdatedAt,
  });
}

class SyncStatusController extends ChangeNotifier {
  static final SyncStatusController _instance = SyncStatusController._internal();
  factory SyncStatusController() => _instance;
  SyncStatusController._internal();

  int _activeRequests = 0;
  SyncStatusState _state = const SyncStatusState(isSyncing: false);

  SyncStatusState get state => _state;

  void startSync() {
    _activeRequests += 1;
    if (!_state.isSyncing) {
      _state = SyncStatusState(
        isSyncing: true,
        lastUpdatedAt: _state.lastUpdatedAt,
      );
      notifyListeners();
    }
  }

  void endSync({DateTime? updatedAt}) {
    if (_activeRequests > 0) {
      _activeRequests -= 1;
    }

    if (_activeRequests == 0) {
      _state = SyncStatusState(
        isSyncing: false,
        lastUpdatedAt: updatedAt ?? DateTime.now(),
      );
      notifyListeners();
    }
  }

  void reset() {
    _activeRequests = 0;
    _state = const SyncStatusState(isSyncing: false);
    notifyListeners();
  }
}
