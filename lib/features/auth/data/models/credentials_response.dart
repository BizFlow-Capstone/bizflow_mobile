class CredentialsResponse {
  final bool success;
  final String message;
  final List<String> credentialTypes;

  CredentialsResponse({
    required this.success,
    required this.message,
    required this.credentialTypes,
  });

  factory CredentialsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    final extractedTypes = <String>{};

    String? normalizeType(dynamic raw) {
      if (raw == null) {
        return null;
      }
      final value = raw.toString().trim().toLowerCase();
      if (value.isEmpty) {
        return null;
      }
      if (value.contains('google')) {
        return 'google';
      }
      if (value.contains('email')) {
        return 'email';
      }
      if (value.contains('phone')) {
        return 'phone';
      }
      return null;
    }

    bool isTruthy(dynamic value) {
      if (value == true) {
        return true;
      }
      if (value is num) {
        return value != 0;
      }
      final text = value?.toString().trim().toLowerCase();
      return text == 'true' || text == '1' || text == 'yes';
    }

    if (data is Map<String, dynamic>) {
      if (isTruthy(data['hasPhone']) || isTruthy(data['phoneLinked'])) {
        extractedTypes.add('phone');
      }
      if (isTruthy(data['hasEmail']) || isTruthy(data['emailLinked'])) {
        extractedTypes.add('email');
      }
      if (isTruthy(data['hasGoogle']) || isTruthy(data['googleLinked'])) {
        extractedTypes.add('google');
      }

      final methodKeys = [
        data['type'],
        data['credentialType'],
        data['provider'],
        data['method'],
        data['name'],
      ];
      for (final key in methodKeys) {
        final type = normalizeType(key);
        if (type != null) {
          extractedTypes.add(type);
        }
      }
    }

    final dynamic rawCredentials = (data is Map<String, dynamic>)
        ? (data['credentials'] ?? data['items'] ?? data['methods'])
        : data;

    final List<dynamic> credentialItems = rawCredentials is List<dynamic>
        ? rawCredentials
        : const <dynamic>[];

    extractedTypes.addAll(
      credentialItems
          .map((item) {
            if (item is String) {
              return normalizeType(item);
            }
            if (item is Map<String, dynamic>) {
              return normalizeType(
                item['type'] ??
                    item['credentialType'] ??
                    item['provider'] ??
                    item['method'] ??
                    item['name'],
              );
            }
            return null;
          })
          .whereType<String>()
          .toSet(),
    );

    return CredentialsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      credentialTypes: extractedTypes.toList(),
    );
  }
}
