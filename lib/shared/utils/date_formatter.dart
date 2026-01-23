import 'package:intl/intl.dart';

/// Date Formatter - Common date formatting functions
class DateFormatter {
  DateFormatter._();

  // Date formats
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Format to date string (dd/MM/yyyy)
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  /// Format to time string (HH:mm)
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return _timeFormat.format(date);
  }

  /// Format to date time string (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return _dateTimeFormat.format(date);
  }

  /// Format to full date string (Monday, 01 January 2024)
  static String formatFullDate(DateTime? date) {
    if (date == null) return '';
    return _fullDateFormat.format(date);
  }

  /// Format to month year string (January 2024)
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return _monthYearFormat.format(date);
  }

  /// Format to short date string (01 Jan)
  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return _shortDateFormat.format(date);
  }

  /// Format to ISO string (yyyy-MM-dd)
  static String formatIso(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  /// Parse date from string
  static DateTime? parse(String? dateString, {String? format}) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      if (format != null) {
        return DateFormat(format).parse(dateString);
      }
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Format relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelative(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
}
