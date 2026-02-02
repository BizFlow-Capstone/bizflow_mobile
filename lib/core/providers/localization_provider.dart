import 'package:flutter/material.dart';

/// Localization Provider - Quản lý việc thay đổi ngôn ngữ cho toàn ứng dụng
class LocalizationProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('vi');

  Locale get currentLocale => _currentLocale;

  /// Thay đổi ngôn ngữ hiện tại
  void setLocale(Locale locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }

  /// Chuyển đổi giữa Tiếng Việt và English
  void toggleLocale() {
    final newLocale = _currentLocale.languageCode == 'vi'
        ? const Locale('en')
        : const Locale('vi');
    setLocale(newLocale);
  }

  /// Reset về Tiếng Việt (mặc định)
  void reset() {
    setLocale(const Locale('vi'));
  }
}
