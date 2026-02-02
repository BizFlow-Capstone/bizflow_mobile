import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supported locales
enum AppLocale {
  vi('vi', 'Tiếng Việt'),
  en('en', 'English');

  final String code;
  final String name;

  const AppLocale(this.code, this.name);

  Locale get locale => Locale(code);
}

/// App Localizations
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  /// Helper method để lấy instance hiện tại
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Supported locales
  static List<Locale> get supportedLocales =>
      AppLocale.values.map((e) => e.locale).toList();

  /// Load JSON file
  Future<bool> load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/localization/${locale.languageCode}.json',
      );
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
      return true;
    } catch (e) {
      print('Error loading localization: $e');
      _localizedStrings = {};
      return false;
    }
  }

  /// Translate key
  /// Ví dụ: translate('auth.login') => 'Đăng nhập'
  String translate(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Return key nếu không tìm thấy
      }
    }

    String result = value.toString();

    // Replace params
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result;
  }

  /// Shorthand method
  String tr(String key, {Map<String, String>? params}) =>
      translate(key, params: params);
}

/// Delegate
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocale.values.any((e) => e.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension để dùng trong UI
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, {Map<String, String>? params}) =>
      l10n.translate(key, params: params);
}
