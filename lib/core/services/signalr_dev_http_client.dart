import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:signalr_netcore/signalr_http_client.dart';

class SignalRDevHttpClient extends SignalRHttpClient {
  final bool allowBadCertificatesForLocal;

  SignalRDevHttpClient({this.allowBadCertificatesForLocal = true});

  @override
  Future<SignalRHttpResponse> send(SignalRHttpRequest request) async {
    final method = request.method;
    final url = request.url;

    if (method == null || method.isEmpty) {
      throw ArgumentError('No method defined.');
    }

    if (url == null || url.isEmpty) {
      throw ArgumentError('No url defined.');
    }

    final uri = Uri.parse(url);
    final ioHttpClient = HttpClient();

    if (allowBadCertificatesForLocal &&
        uri.scheme == 'https' &&
        _isLocalAddress(uri.host)) {
      ioHttpClient.badCertificateCallback = (_, __, ___) => true;
    }

    final client = IOClient(ioHttpClient);

    try {
      final headers = <String, String>{
        'X-Requested-With': 'FlutterHttpClient',
        ...?request.headers?.asMap,
      };

      final hasBody = request.content != null;
      if (!headers.keys
          .map((header) => header.toLowerCase())
          .contains('content-type')) {
        headers['content-type'] = hasBody && request.content is String
            ? 'application/json;charset=UTF-8'
            : 'text/plain;charset=UTF-8';
      }

      Future<http.Response> responseFuture;
      switch (method.toUpperCase()) {
        case 'POST':
          responseFuture = client.post(
            uri,
            body: request.content,
            headers: headers,
          );
          break;
        case 'PUT':
          responseFuture = client.put(
            uri,
            body: request.content,
            headers: headers,
          );
          break;
        case 'DELETE':
          responseFuture = client.delete(
            uri,
            body: request.content,
            headers: headers,
          );
          break;
        case 'GET':
        default:
          responseFuture = client.get(uri, headers: headers);
          break;
      }

      final timeoutMs = request.timeout;
      if (timeoutMs != null && timeoutMs > 0) {
        responseFuture = responseFuture.timeout(
          Duration(milliseconds: timeoutMs),
        );
      }

      final response = await responseFuture;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SignalRHttpResponse(
          response.statusCode,
          statusText: response.reasonPhrase,
          content: response.body,
        );
      }

      throw Exception(
        'SignalR HTTP error: ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    } finally {
      client.close();
    }
  }

  bool _isLocalAddress(String host) {
    return host == 'localhost' ||
        host == '10.0.2.2' ||
        host.startsWith('192.168.') ||
        host.startsWith('172.16.') ||
        host.startsWith('172.17.') ||
        host.startsWith('172.18.') ||
        host.startsWith('172.19.') ||
        host.startsWith('172.2') ||
        host.startsWith('172.3');
  }
}
