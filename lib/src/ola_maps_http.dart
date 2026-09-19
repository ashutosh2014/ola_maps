import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ola_maps/src/utilities/exceptions.dart';
import 'package:ola_maps/src/utilities/models.dart';
import 'package:ola_maps/src/utilities/ola_maps_language.dart';

/// Shared HTTP helper for Ola Maps REST APIs (`https://api.olamaps.io`).
class OlaMapsHttp {
  /// Default REST origin (`https://api.olamaps.io`).
  static const defaultBaseUrl = 'https://api.olamaps.io';

  /// Dashboard API key appended as `api_key`.
  final String apiKey;

  /// REST origin. Defaults to [defaultBaseUrl].
  final String baseUrl;

  /// ISO 639-1 code applied when a call omits `language`.
  final String? defaultLanguage;
  final http.Client _client;

  /// Creates a shared HTTP client for Places, Routing, and related APIs.
  OlaMapsHttp({
    required this.apiKey,
    this.baseUrl = defaultBaseUrl,
    this.defaultLanguage,
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

  /// ISO 639-1 code for Places, Routing, Geocoding, and Maps. Per-call
  /// [language] wins; otherwise [defaultLanguage] from [Olamaps.initialize].
  String? resolvedLanguage([Object? language]) {
    if (language != null) return OlaMapsLanguage.codeOf(language);
    if (defaultLanguage == null || defaultLanguage!.trim().isEmpty) {
      return null;
    }
    return OlaMapsLanguage.codeOf(defaultLanguage);
  }

  /// Copies [query] and sets `language` from [language] or [defaultLanguage].
  Map<String, dynamic> withLanguage(
    Map<String, dynamic> query, {
    Object? language,
  }) {
    final existing = query['language'];
    final code = existing != null
        ? OlaMapsLanguage.codeOf(existing)
        : resolvedLanguage(language);
    if (code != null) query['language'] = code;
    return query;
  }

  /// Same as [withLanguage] for a JSON map body.
  Object? withLanguageBody(Object? body, {Object? language}) {
    if (body is! Map) return body;
    return withLanguage(Map<String, dynamic>.from(body), language: language);
  }

  /// GET [path] and decode JSON.
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

  /// POST, PUT, or DELETE [path] with an optional JSON [body].
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

  /// GET [path] and return the raw body (static maps).
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

  /// Random `X-Request-Id` value.
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

  /// Encodes points as `lat,lng|lat,lng` for Roads / Routing query params.
  static String encodePoints(Iterable<Location> points) {
    return points.map((point) => '${point.lat},${point.lng}').join('|');
  }
}
