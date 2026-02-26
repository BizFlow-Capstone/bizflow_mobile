import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer - Delay execution until pause in events
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Throttler - Limit execution to once per duration
class Throttler {
  final Duration delay;
  DateTime? _lastExecution;

  Throttler({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) > delay) {
      _lastExecution = now;
      action();
    }
  }

  void reset() {
    _lastExecution = null;
  }
}

/// Logger - Simple logging utility
class AppLogger {
  AppLogger._();

  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void debug(String message, {String? tag}) {
    if (_enabled && kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔵 DEBUG: $prefix$message');
    }
  }

  static void info(String message, {String? tag}) {
    if (_enabled && kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🟢 INFO: $prefix$message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (_enabled && kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🟡 WARNING: $prefix$message');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled && kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔴 ERROR: $prefix$message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }
}

/// String Utils
class StringUtils {
  StringUtils._();

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map(capitalize).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  static String removeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  /// Check if string is null or empty
  static bool isNullOrEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Get initials from name
  static String getInitials(String name, {int count = 2}) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .take(count)
        .map((word) => word[0].toUpperCase())
        .join();
    return initials;
  }

  /// Mask string (e.g., email, phone)
  static String mask(
    String text, {
    int visibleStart = 3,
    int visibleEnd = 3,
    String maskChar = '*',
  }) {
    if (text.length <= visibleStart + visibleEnd) return text;
    final start = text.substring(0, visibleStart);
    final end = text.substring(text.length - visibleEnd);
    final maskLength = text.length - visibleStart - visibleEnd;
    return '$start${maskChar * maskLength}$end';
  }
}
