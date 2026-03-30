import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

/// Currency Formatter - Format currency values
class CurrencyFormatter {
  CurrencyFormatter._();

  // Custom VN Format (using en_US to get commas as thousand separators)
  static final _customVndFormat = NumberFormat('#,###', 'en_US');

  // US Dollar
  static final _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Number format (with commas)
  static final _numberFormat = NumberFormat('#,###', 'en_US');

  /// Format to VND (e.g. 65,000đ)
  static String formatVND(num? amount) {
    if (amount == null) return '0đ';
    return '${_customVndFormat.format(amount)}đ';
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

  /// Format date to dd/MM/yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
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

/// Currency Input Formatter for TextFields
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove any non-digit characters
    final cleanedText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(cleanedText) ?? 0;

    // Format the number with commas
    final newText = NumberFormat('#,###', 'en_US').format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length,
      ), // Always put cursor at the end
    );
  }
}
