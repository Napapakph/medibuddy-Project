import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_manager.dart';

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner;

  CustomHttpClient({http.Client? client}) : _inner = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. ส่ง Request ครั้งแรก
    var response = await _inner.send(request);

    // 2. ถ้าเจอ 401 (Unauthorized) ให้ทำการ Refresh Token แบบลับๆ
    if (response.statusCode == 401) {
      debugPrint(
          '⚠️ CustomHttpClient: 401 Unauthorized encountered. Attempting to refresh token...');

      try {
        final newToken = await AuthManager.service.refreshToken();

        if (newToken != null && newToken.isNotEmpty) {
          debugPrint(
              '✅ CustomHttpClient: Token refreshed successfully. Retrying request...');

          // ต้องทิ้ง Stream response อันเก่าก่อน
          await response.stream.drain();

          // HTTP package ไม่อนุญาตให้ใช้ Request เดิมยิงซ้ำ ต้องสำเนา (Clone)
          final retryRequest = _copyRequest(request);

          // เอา Token ใหม่ใส่ใน Header
          retryRequest.headers['Authorization'] = 'Bearer $newToken';

          // 3. ทำการยิง Request ใหม่ที่เหมือนเดิมทุกประการอีกรอบด้วย Token ใหม่
          response = await _inner.send(retryRequest);
        } else {
          debugPrint('❌ CustomHttpClient: Refresh token failed or is null.');
        }
      } catch (e) {
        debugPrint('❌ CustomHttpClient: Refresh process exception: $e');
      }
    }

    return response;
  }

  /// Helper สำหรับทำสำเนา HTTP Request
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
