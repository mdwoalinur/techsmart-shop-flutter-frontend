import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_environment.dart';
import 'api_exception.dart';

typedef AccessTokenReader = Future<String?> Function();
typedef AccessTokenRefresher = Future<bool> Function();
typedef SessionInvalidHandler = Future<void> Function();

class ApiClient {
  ApiClient({
    http.Client? client,
    Uri? baseUri,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? AppEnvironment.apiBaseUri;
  final http.Client _client;
  final Uri _baseUri;
  final Duration requestTimeout;
  AccessTokenReader? _token;
  AccessTokenRefresher? _refresh;
  SessionInvalidHandler? _invalid;
  Future<bool>? _refreshing;
  static const jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  void configureAuth({
    required AccessTokenReader accessToken,
    required AccessTokenRefresher refresh,
    required SessionInvalidHandler sessionInvalid,
  }) {
    _token = accessToken;
    _refresh = refresh;
    _invalid = sessionInvalid;
  }

  Future<Object?> get(
    String path, {
    Map<String, String?> queryParameters = const {},
    bool authenticated = false,
  }) => _send(
    'GET',
    path,
    queryParameters: queryParameters,
    authenticated: authenticated,
  );
  Future<Object?> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) => _send('POST', path, body: body, authenticated: authenticated);
  Future<Object?> put(
    String path, {
    Object? body,
    bool authenticated = false,
  }) => _send('PUT', path, body: body, authenticated: authenticated);
  Future<Object?> delete(String path, {bool authenticated = false}) =>
      _send('DELETE', path, authenticated: authenticated);
  Future<Object?> postMultipartFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    bool authenticated = false,
  }) => _sendMultipartFile(
    path,
    fieldName: fieldName,
    bytes: bytes,
    filename: filename,
    authenticated: authenticated,
  );
  void close() => _client.close();
  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String?> queryParameters = const {},
    bool authenticated = false,
    bool retried = false,
  }) async {
    final uri = _resolve(path, queryParameters);
    _safeLog('$method ${uri.path}');
    try {
      final request = http.Request(method, uri)..headers.addAll(jsonHeaders);
      if (authenticated) {
        final token = await _token?.call();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(requestTimeout);
      final response = await http.Response.fromStream(streamed);
      _safeLog('$method ${uri.path} -> ${response.statusCode}');
      if (authenticated &&
          response.statusCode == 401 &&
          !retried &&
          await _refreshOnce()) {
        return _send(
          method,
          path,
          body: body,
          queryParameters: queryParameters,
          authenticated: true,
          retried: true,
        );
      }
      if (authenticated && response.statusCode == 401) await _invalid?.call();
      return _parseResponse(response);
    } on TimeoutException catch (e) {
      throw ApiException(
        type: ApiExceptionType.timeout,
        message: 'The request timed out. Please try again.',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        type: ApiExceptionType.network,
        message: 'Unable to connect to the server. Please try again.',
        cause: e,
      );
    } on ApiException {
      rethrow;
    } on FormatException catch (e) {
      throw ApiException(
        type: ApiExceptionType.invalidResponse,
        message: 'The server returned an unreadable response.',
        cause: e,
      );
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.request,
        message: 'The request could not be completed.',
        cause: e,
      );
    }
  }

  Future<Object?> _sendMultipartFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    bool authenticated = false,
    bool retried = false,
  }) async {
    final uri = _resolve(path, const {});
    _safeLog('POST ${uri.path} multipart');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: _safeFilename(filename),
          ),
        );
      if (authenticated) {
        final token = await _token?.call();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }
      final streamed = await _client.send(request).timeout(requestTimeout);
      final response = await http.Response.fromStream(streamed);
      _safeLog('POST ${uri.path} multipart -> ${response.statusCode}');
      if (authenticated &&
          response.statusCode == 401 &&
          !retried &&
          await _refreshOnce()) {
        return _sendMultipartFile(
          path,
          fieldName: fieldName,
          bytes: bytes,
          filename: filename,
          authenticated: true,
          retried: true,
        );
      }
      if (authenticated && response.statusCode == 401) await _invalid?.call();
      return _parseResponse(response);
    } on TimeoutException catch (e) {
      throw ApiException(
        type: ApiExceptionType.timeout,
        message: 'The request timed out. Please try again.',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        type: ApiExceptionType.network,
        message: 'Unable to connect to the server. Please try again.',
        cause: e,
      );
    } on ApiException {
      rethrow;
    } on FormatException catch (e) {
      throw ApiException(
        type: ApiExceptionType.invalidResponse,
        message: 'The server returned an unreadable response.',
        cause: e,
      );
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.request,
        message: 'The request could not be completed.',
        cause: e,
      );
    }
  }

  String _safeFilename(String filename) {
    final clean = filename.trim().split(RegExp(r'[\\/]')).last;
    return clean.isEmpty ? 'profile-photo.jpg' : clean;
  }

  Future<bool> _refreshOnce() async {
    if (_refresh == null) return false;
    final current = _refreshing;
    if (current != null) return current;
    final future = _refresh!();
    _refreshing = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  Uri _resolve(String path, Map<String, String?> qp) {
    final clean = path.trim().replaceFirst(RegExp(r'^/+'), '');
    final base = _baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final q = <String, String>{
      for (final e in qp.entries)
        if (e.value != null) e.key: e.value!,
    };
    return _baseUri.replace(
      path: '$base/$clean',
      queryParameters: q.isEmpty ? null : q,
    );
  }

  Object? _parseResponse(http.Response r) {
    final Object? decoded = r.body.trim().isEmpty
        ? null
        : jsonDecode(utf8.decode(r.bodyBytes));
    final msg = decoded is Map<String, Object?>
        ? decoded['message'] as String?
        : null;
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw ApiException(
        type: ApiExceptionType.unauthorized,
        message: r.statusCode == 401
            ? 'Your session has expired. Please sign in again.'
            : 'You do not have permission to perform this action.',
        statusCode: r.statusCode,
        responseBody: decoded,
      );
    }
    if (r.statusCode >= 500) {
      throw ApiException(
        type: ApiExceptionType.server,
        message: msg ?? 'The server is temporarily unavailable.',
        statusCode: r.statusCode,
        responseBody: decoded,
      );
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(
        type: ApiExceptionType.request,
        message: msg ?? 'The server rejected the request.',
        statusCode: r.statusCode,
        responseBody: decoded,
      );
    }
    return decoded;
  }

  void _safeLog(String m) {
    if (kDebugMode) debugPrint('[ApiClient] $m');
  }
}
