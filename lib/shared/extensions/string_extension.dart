/// String Extensions
extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is valid phone
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$');
    return phoneRegex.hasMatch(replaceAll(' ', ''));
  }

  /// Check if string is valid URL
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegex.hasMatch(this);
  }

  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Convert to int (nullable)
  int? get toIntOrNull => int.tryParse(this);

  /// Convert to double (nullable)
  double? get toDoubleOrNull => double.tryParse(this);

  /// Check if string is null or empty
  bool get isNullOrEmpty => trim().isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => trim().isNotEmpty;
}

/// Nullable String Extensions
extension NullableStringExtension on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.trim().isNotEmpty;

  /// Return empty string if null
  String get orEmpty => this ?? '';

  /// Return value or default
  String orDefault(String defaultValue) => isNullOrEmpty ? defaultValue : this!;
}
