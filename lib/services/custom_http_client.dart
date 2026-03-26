import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_manager.dart';
import 'token_manager.dart';

class CustomHttpClient extends http.BaseClient {
  static const String _invalidTokenError =
      'Unauthorized - Invalid or missing token';
  final http.Client _inner;

  CustomHttpClient({http.Client? client}) : _inner = client ?? http.Client();

  bool _isInvalidTokenBody(String body) {
    if (body.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error']?.toString();
        final message = decoded['message']?.toString();
        if (error == _invalidTokenError || message == _invalidTokenError) {
          return true;
        }
      }
    } catch (_) {}
    return body.contains(_invalidTokenError);
  }

  http.StreamedResponse _rebuildResponse(
    http.StreamedResponse response,
    List<int> bodyBytes,
  ) {
    return http.StreamedResponse(
      Stream.fromIterable([bodyBytes]),
      response.statusCode,
      contentLength: bodyBytes.length,
      headers: response.headers,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var response = await _inner.send(request);

    if (response.statusCode == 401) {
      final bodyBytes = await response.stream.toBytes();
      final bodyText = utf8.decode(bodyBytes, allowMalformed: true);

      if (_isInvalidTokenBody(bodyText)) {
        debugPrint('CustomHttpClient: 401 invalid/missing token. Expiring session.');
        await TokenManager.expireSession(
            reason: '401 invalid/missing access token');
        return _rebuildResponse(response, bodyBytes);
      }

      debugPrint(
          'CustomHttpClient: 401 Unauthorized encountered. Attempting to refresh token...');

      try {
        final newToken = await AuthManager.service.refreshToken();

        if (newToken != null && newToken.isNotEmpty) {
          debugPrint(
              'CustomHttpClient: Token refreshed successfully. Retrying request...');

          final retryRequest = _copyRequest(request);

          retryRequest.headers['Authorization'] = 'Bearer $newToken';

          response = await _inner.send(retryRequest);
          return response;
        } else {
          debugPrint('CustomHttpClient: Refresh token failed or is null.');
          // TokenManager.onSessionExpired will handle redirect to login
        }
      } catch (e) {
        debugPrint('CustomHttpClient: Refresh process exception: $e');
        // TokenManager.onSessionExpired will handle redirect to login
      }

      return _rebuildResponse(response, bodyBytes);
    }

    return response;
  }

  http.BaseRequest _copyRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final req = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      req.headers.addAll(request.headers);
      return req;
    } else if (request is http.MultipartRequest) {
      final req = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      req.headers.addAll(request.headers);
      return req;
    } else {
      // Fallback
      final req = http.Request(request.method, request.url);
      req.headers.addAll(request.headers);
      return req;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

