import 'package:intl/intl.dart';

/// Currency Formatter - Format currency values
class CurrencyFormatter {
  CurrencyFormatter._();

  // Vietnam Dong
  static final _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  // US Dollar
  static final _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Number format (no currency symbol)
  static final _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Format to VND
  static String formatVND(num? amount) {
    if (amount == null) return '0 ₫';
    return _vndFormat.format(amount);
  }

  /// Format to USD
  static String formatUSD(num? amount) {
    if (amount == null) return '\$0.00';
    return _usdFormat.format(amount);
  }

  /// Format number with thousand separators
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return _numberFormat.format(value);
  }

  /// Format compact (e.g., 1K, 1M, 1B)
  static String formatCompact(num? value) {
    if (value == null) return '0';
    return NumberFormat.compact().format(value);
  }

  /// Format percentage
  static String formatPercent(num? value, {int decimalDigits = 1}) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  /// Parse currency string to number
  static num? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    // Remove all non-numeric characters except dot and minus
    final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return num.tryParse(cleaned);
  }
}

/// Number Utils
class NumberUtils {
  NumberUtils._();

  /// Clamp value between min and max
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Round to specific decimal places
  static double roundTo(double value, int places) {
    final mod = 10.0 * places;
    return ((value * mod).round().toDouble() / mod);
  }

  /// Check if value is between range
  static bool isBetween(num value, num min, num max) {
    return value >= min && value <= max;
  }
}
