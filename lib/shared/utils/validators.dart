/// Validators - Common validation functions
class Validators {
  Validators._();

  /// Check if email is valid
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Check if password is valid (min 8 chars, at least 1 letter and 1 number)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    return hasLetter && hasNumber;
  }

  /// Check if phone is valid (Vietnam format)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  /// Check if string is not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Check if string has minimum length
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// Check if string has maximum length
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  /// Check if value is numeric
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  /// Check if value is integer
  static bool isInteger(String value) {
    return int.tryParse(value) != null;
  }

  /// Check if URL is valid
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegex.hasMatch(url);
  }

  // Form field validators (return error message or null)

  static String? validateRequired(String? value, [String? fieldName]) {
    if (!isNotEmpty(value)) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (!isNotEmpty(value)) {
      return 'Email is required';
    }
    if (!isValidEmail(value!)) {
      return 'Invalid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (!isNotEmpty(value)) {
      return 'Password is required';
    }
    if (!isValidPassword(value!)) {
      return 'Password must be at least 8 characters with letters and numbers';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (!isNotEmpty(value)) {
      return 'Phone number is required';
    }
    if (!isValidPhone(value!)) {
      return 'Invalid phone number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (!isNotEmpty(value)) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength, [String? fieldName]) {
    if (!isNotEmpty(value)) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    if (!hasMinLength(value!, minLength)) {
      return fieldName != null
          ? '$fieldName must be at least $minLength characters'
          : 'Must be at least $minLength characters';
    }
    return null;
  }
}
