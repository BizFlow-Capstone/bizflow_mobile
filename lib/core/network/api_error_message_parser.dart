import 'package:dio/dio.dart';

import 'api_client.dart';

class ApiErrorMessageParser {
  static const String genericMessage = 'Có lỗi xảy ra, vui lòng thử lại';

  static String parse(
    Object error, {
    String fallback = genericMessage,
  }) {
    if (error is DioException) {
      final payloadMessage = _extractFromPayload(error.response?.data);
      if (payloadMessage != null && payloadMessage.isNotEmpty) {
        return payloadMessage;
      }

      final cleanFromMessage = _stripTechnicalPrefix(error.message);
      if (cleanFromMessage != null && cleanFromMessage.isNotEmpty) {
        return cleanFromMessage;
      }

      return fallback;
    }

    if (error is ApiException) {
      final payloadMessage = _extractFromPayload(error.data);
      if (payloadMessage != null && payloadMessage.isNotEmpty) {
        return payloadMessage;
      }

      final cleanFromMessage = _stripTechnicalPrefix(error.message);
      if (cleanFromMessage != null && cleanFromMessage.isNotEmpty) {
        return cleanFromMessage;
      }

      return fallback;
    }

    final clean = _stripTechnicalPrefix(error.toString());
    if (clean != null && clean.isNotEmpty) {
      return clean;
    }

    return fallback;
  }

  static String? _extractFromPayload(dynamic payload) {
    if (payload is String) {
      return _stripTechnicalPrefix(payload);
    }

    if (payload is! Map) {
      return null;
    }

    final map = payload.cast<dynamic, dynamic>();

    for (final key in const ['message', 'detail', 'title', 'error']) {
      final value = map[key];
      if (value != null) {
        final clean = _stripTechnicalPrefix(value.toString());
        if (clean != null && clean.isNotEmpty) {
          return clean;
        }
      }
    }

    final errors = map['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        final clean = _stripTechnicalPrefix(firstValue.first?.toString());
        if (clean != null && clean.isNotEmpty) {
          return clean;
        }
      }

      final clean = _stripTechnicalPrefix(firstValue?.toString());
      if (clean != null && clean.isNotEmpty) {
        return clean;
      }
    }

    return null;
  }

  static String? _stripTechnicalPrefix(String? input) {
    if (input == null) return null;

    var value = input.trim();
    if (value.isEmpty) return null;

    value = value.replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '');
    value = value.replaceFirst(
      RegExp(r'^ApiException:\s*\[\d+\]\s*', caseSensitive: false),
      '',
    );
    value = value.trim();

    if (value.isEmpty) return null;
    return value;
  }
}