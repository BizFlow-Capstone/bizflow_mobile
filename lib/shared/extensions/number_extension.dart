/// Number Extensions
extension NumExtension on num {
  /// Check if value is between range (inclusive)
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  /// Clamp value between min and max
  num clampBetween(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Check if value is positive
  bool get isPositive => this > 0;

  /// Check if value is negative
  bool get isNegative => this < 0;

  /// Check if value is zero
  bool get isZero => this == 0;

  /// Duration helpers
  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
  Duration get hours => Duration(hours: toInt());
  Duration get days => Duration(days: toInt());
}

/// Int Extensions
extension IntExtension on int {
  /// Check if is even
  bool get isEvenNumber => this % 2 == 0;

  /// Check if is odd
  bool get isOddNumber => this % 2 != 0;

  /// Get ordinal string (1st, 2nd, 3rd, etc.)
  String get ordinal {
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }

  /// Iterate n times
  void times(void Function(int index) action) {
    for (var i = 0; i < this; i++) {
      action(i);
    }
  }

  /// Generate list from 0 to n-1
  List<int> get range => List.generate(this, (index) => index);
}

/// Double Extensions
extension DoubleExtension on double {
  /// Round to specific decimal places
  double roundTo(int places) {
    final mod = 10.0 * places;
    return ((this * mod).round().toDouble() / mod);
  }

  /// Format to percentage string
  String toPercent({int decimalDigits = 1}) {
    return '${toStringAsFixed(decimalDigits)}%';
  }
}

/// Nullable Num Extensions
extension NullableNumExtension on num? {
  /// Return 0 if null
  num get orZero => this ?? 0;

  /// Return value or default
  num orDefault(num defaultValue) => this ?? defaultValue;

  /// Check if is null or zero
  bool get isNullOrZero => this == null || this == 0;
}
