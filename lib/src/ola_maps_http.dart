import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ola_maps/src/utilities/exceptions.dart';
import 'package:ola_maps/src/utilities/models.dart';

/// Shared HTTP helper for Ola Maps REST APIs (`https://api.olamaps.io`).
class OlaMapsHttp {
  static const defaultBaseUrl = 'https://api.olamaps.io';

  final String apiKey;
  final String baseUrl;
  final http.Client _client;

  OlaMapsHttp({
    required this.apiKey,
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _headers({
    String? requestId,
    String? correlationId,
    Map<String, String>? extra,
    bool jsonBody = false,
  }) {
    return {
      'Accept': 'application/json',
      'X-Request-Id': requestId ?? uuidV4(),
      if (correlationId != null) 'X-Correlation-Id': correlationId,
      if (jsonBody) 'Content-Type': 'application/json',
      ...?extra,
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, dynamic>{
      'api_key': apiKey,
    };
    query?.forEach((key, value) {
      if (value == null) return;
      if (value is Iterable && value is! String) {
        final items = value.map((item) => item.toString()).where((item) => item.isNotEmpty);
        if (items.isEmpty) return;
        params[key] = items.toList();
      } else if (value is bool) {
        params[key] = value.toString();
      } else {
        params[key] = value.toString();
      }
    });
    return Uri.parse('$baseUrl$path').replace(queryParameters: params);
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
    String? requestId,
    String? correlationId,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: _headers(requestId: requestId, correlationId: correlationId),
    );
    return _decode(response);
  }

  Future<dynamic> sendJson(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? requestId,
    String? correlationId,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(
      requestId: requestId,
      correlationId: correlationId,
      jsonBody: body != null,
    );
    final encoded = body == null ? null : jsonEncode(body);
    late http.Response response;
    switch (method) {
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encoded);
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        response = await _client.delete(uri, headers: headers, body: encoded);
      default:
        throw ApiException('Unsupported HTTP method $method');
    }
    return _decode(response);
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? query,
    String? requestId,
    String? correlationId,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: _headers(requestId: requestId, correlationId: correlationId),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    _throwForStatus(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return json.decode(response.body);
    }
    _throwForStatus(response);
  }

  Never _throwForStatus(http.Response response) {
    String message = response.body;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map) {
        message = (decoded['error_message'] ??
                decoded['message'] ??
                decoded['error'] ??
                decoded['status'] ??
                message)
            .toString();
      }
    } catch (_) {}
    switch (response.statusCode) {
      case 400:
        throw BadRequestException(message);
      case 401:
        throw UnauthorizedException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        throw UnprocessableException(message);
      case 500:
        throw ServerException(message);
      default:
        throw ApiException('HTTP ${response.statusCode}: $message');
    }
  }

  static String uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  static String encodePoints(Iterable<Location> points) {
    return points.map((point) => '${point.lat},${point.lng}').join('|');
  }
}
