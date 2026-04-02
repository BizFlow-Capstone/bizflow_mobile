/// Prevents rapid duplicate invocations of async operations, such as
/// create / update / delete API calls triggered by button taps while the
/// network is slow.
///
/// Usage (StatefulWidget):
/// ```dart
/// final _guard = ActionGuard();
///
/// void _onSave() => _guard.run(context, () async {
///   await repository.save(...);
/// });
/// ```
class ActionGuard {
  bool _isRunning = false;

  /// Whether an action is in progress.
  bool get isRunning => _isRunning;

  /// Executes [action] only when no previous call is still in progress.
  ///
  /// Returns `true` if [action] was allowed to run, `false` if it was
  /// suppressed because a previous call hasn't finished yet.
  Future<bool> run(Future<void> Function() action) async {
    if (_isRunning) return false;
    _isRunning = true;
    try {
      await action();
      return true;
    } finally {
      _isRunning = false;
    }
  }

  /// Synchronous variant — suppresses the second call until [action] returns.
  bool runSync(void Function() action) {
    if (_isRunning) return false;
    _isRunning = true;
    try {
      action();
      return true;
    } finally {
      _isRunning = false;
    }
  }

  /// Resets the guard in case [run] threw an unhandled exception and the guard
  /// got stuck in the locked state.
  void reset() {
    _isRunning = false;
  }
}
