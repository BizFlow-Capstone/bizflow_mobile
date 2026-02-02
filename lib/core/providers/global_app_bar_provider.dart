import 'package:flutter/material.dart';

/// Global AppBar Config
/// Được dùng bởi ShellRoute (Navigator) để render AppBar chung
class AppBarConfig {
  final String userName;
  final Function(Locale)? onLocaleChange;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  AppBarConfig({
    required this.userName,
    this.onLocaleChange,
    this.onNotificationTap,
    this.onSettingsTap,
    this.scaffoldKey,
  });

  // Default config
  static AppBarConfig defaultConfig() {
    return AppBarConfig(
      userName: 'User',
      onLocaleChange: null,
      onNotificationTap: null,
      onSettingsTap: null,
      scaffoldKey: null,
    );
  }
}

/// Global AppBar State Provider
/// Cung cấp AppBar state cho toàn bộ hệ thống
class GlobalAppBarNotifier extends ChangeNotifier {
  AppBarConfig _config = AppBarConfig.defaultConfig();

  AppBarConfig get config => _config;

  void updateConfig(AppBarConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  void setUserName(String userName) {
    _config = AppBarConfig(
      userName: userName,
      onLocaleChange: _config.onLocaleChange,
      onNotificationTap: _config.onNotificationTap,
      onSettingsTap: _config.onSettingsTap,
      scaffoldKey: _config.scaffoldKey,
    );
    notifyListeners();
  }
}

