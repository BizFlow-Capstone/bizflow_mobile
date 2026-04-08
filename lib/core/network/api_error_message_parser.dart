import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class ApiErrorMessageParser {
  static const String genericMessage = 'Có lỗi xảy ra, vui lòng thử lại';

  static String parse(Object error, {String fallback = genericMessage}) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return fallback;
      }

      if (_isLikelyNetworkTransportError(error)) {
        return _resolveNetworkTransportMessage(fallback: fallback);
      }

      final payloadMessage = _extractFromPayload(error.response?.data);
      if (payloadMessage != null && payloadMessage.isNotEmpty) {
        return payloadMessage;
      }

      final cleanFromMessage = _stripTechnicalPrefix(error.message);
      if (cleanFromMessage != null && cleanFromMessage.isNotEmpty) {
        return cleanFromMessage;
      }

      return _resolveFallbackByStatus(statusCode, fallback: fallback);
    }

    if (error is ApiException) {
      final statusCode = error.statusCode;
      if (statusCode >= 500) {
        return fallback;
      }

      final payloadMessage = _extractFromPayload(error.data);
      if (payloadMessage != null && payloadMessage.isNotEmpty) {
        return payloadMessage;
      }

      final cleanFromMessage = _stripTechnicalPrefix(error.message);
      if (cleanFromMessage != null && cleanFromMessage.isNotEmpty) {
        return cleanFromMessage;
      }

      return _resolveFallbackByStatus(statusCode, fallback: fallback);
    }

    final clean = _stripTechnicalPrefix(error.toString());
    if (clean != null && clean.isNotEmpty) {
      return clean;
    }

    return fallback;
  }

  static bool _isLikelyNetworkTransportError(DioException error) {
    final type = error.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return true;
    }

    final message = (error.message ?? '').toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('request connection took longer');
  }

  static String _resolveNetworkTransportMessage({required String fallback}) {
    if (_isLocalOnlyBaseUrl(AppConfig.baseUrl)) {
      return 'Khong ket noi duoc API. Ban dang dung mang ngoai WiFi noi bo. Hay doi sang WiFi cung mang backend hoac dat API_BASE_URL la domain public.';
    }
    return fallback;
  }

  static bool _isLocalOnlyBaseUrl(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();

    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }

    if (host.startsWith('192.168.') || host.startsWith('10.')) {
      return true;
    }

    final octets = host.split('.');
    if (octets.length == 4) {
      final first = int.tryParse(octets[0]);
      final second = int.tryParse(octets[1]);
      if (first == 172 && second != null && second >= 16 && second <= 31) {
        return true;
      }
    }

    return false;
  }

  static String _resolveFallbackByStatus(
    int? statusCode, {
    required String fallback,
  }) {
    // Prefer explicit backend messages for 3xx/4xx.
    // Only use generic fallback for server-side/unknown failures.
    if (statusCode == null || statusCode <= 0 || statusCode >= 500) {
      return fallback;
    }
    return fallback == genericMessage ? 'Yeu cau khong hop le' : fallback;
  }

  static String? _extractFromPayload(dynamic payload) {
    if (payload == null) return null;

    if (payload is String) {
      return _stripTechnicalPrefix(payload);
    }

    if (payload is List && payload.isNotEmpty) {
      return _extractFromPayload(payload.first);
    }

    if (payload is! Map) {
      return null;
    }

    final map = payload.cast<dynamic, dynamic>();

    for (final key in const ['message', 'detail', 'title', 'error']) {
      final value = map[key];
      if (value != null) {
        if (value is String) {
          final clean = _stripTechnicalPrefix(value);
          if (clean != null && clean.isNotEmpty) {
            return clean;
          }
        } else if (value is Map || value is List) {
          final extracted = _extractFromPayload(value);
          if (extracted != null && extracted.isNotEmpty) {
            return extracted;
          }
        } else {
          final clean = _stripTechnicalPrefix(value.toString());
          if (clean != null && clean.isNotEmpty) {
            return clean;
          }
        }
      }
    }

    final errors = map['errors'];
    if (errors != null) {
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        final extracted = _extractFromPayload(firstValue);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      } else {
        final extracted = _extractFromPayload(errors);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }
    }

    return null;
  }

  static String? _stripTechnicalPrefix(String? input) {
    if (input == null) return null;

    var value = input.trim();
    if (value.isEmpty) return null;

    // Remove technical labels
    value = value.replaceFirst(
      RegExp(r'^Exception:\s*', caseSensitive: false),
      '',
    );
    value = value.replaceFirst(
      RegExp(r'^ApiException\s*:?\s*\[-?\d+\]\s*:?\s*', caseSensitive: false),
      '',
    );

    // Remove common English prefixes followed by a colon (e.g., "Error loading products:", "Failed to refresh:")
    // This regex looks for 1-5 words at the start ending with a colon.
    value = value.replaceFirst(
      RegExp(
        r'^(Error|Failed|Message|Detail|Exception)\s+[^:]+:\s*',
        caseSensitive: false,
      ),
      '',
    );

    // Additional generic cleanup for leading colons or dashes
    value = value.replaceFirst(RegExp(r'^[ :\-]+'), '');

    value = value.trim();

    if (value.isEmpty) return null;
    return value;
  }
}
