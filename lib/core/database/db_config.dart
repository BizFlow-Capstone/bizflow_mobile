class DbConfig {
  DbConfig._();

  static const String defaultDbFileName = 'bizflow_local.db';

  static String databaseFileNameForUser(String? userScope) {
    final normalized = _normalize(userScope);
    if (normalized == null) {
      return defaultDbFileName;
    }
    return 'bizflow_$normalized.db';
  }

  static String? _normalize(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final sanitized = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (sanitized.isEmpty) {
      return null;
    }
    return sanitized;
  }
}
