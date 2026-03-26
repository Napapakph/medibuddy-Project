import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_manager.dart';

class AuthInterceptor extends Interceptor {
  static const String _invalidTokenError =
      'Unauthorized - Invalid or missing token';

  bool _isInvalidTokenError(DioException err) {
    final data = err.response?.data;
    if (data == null) return false;

    if (data is Map) {
      final error = data['error']?.toString();
      final message = data['message']?.toString();
      if (error == _invalidTokenError || message == _invalidTokenError) {
        return true;
      }
    } else if (data is String) {
      if (data.contains(_invalidTokenError)) return true;
    }

    return false;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. We skip intercepting requests to the refresh endpoint itself
    if (options.path.contains('/api/auth/v2/refresh') ||
        options.path.contains('/api/auth/v2/login') ||
        options.path.contains('/api/auth/v2/register')) {
      return handler.next(options);
    }

    // 2. Proactively get an access token.
    // If it's about to expire, TokenManager will refresh it first under the hood.
    final token = await TokenManager.getValidAccessToken();

    // 3. Attach token if available
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 1. Skip if the error is not 401 Unauthorized
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // If backend says token is invalid/missing -> We will STILL TRY to refresh it
    // instead of kicking the user out immediately.
    if (_isInvalidTokenError(err)) {
      debugPrint(
          'AuthInterceptor: 401 invalid/missing token detected. Will attempt to refresh first.');
      // เราจะไม่สั่ง expireSession ทันทีแล้ว แต่จะปล่อยไหลลงไปให้มันขอ Refresh ด้านล่าง
    }

    final requestOptions = err.requestOptions;

    // 2. Prevent infinite loops: skip if already retried
    if (requestOptions.extra['isRetry'] == true) {
      debugPrint('AuthInterceptor: 401 on a retry request. Passing error.');
      return handler.next(err);
    }

    // 3. Skip if the error happened during the refresh endpoint
    if (requestOptions.path.contains('/api/auth/v2/refresh')) {
      debugPrint(
          'AuthInterceptor: 401 on refresh endpoint itself. Passing error.');
      await TokenManager.clear();
      return handler.next(err);
    }

    debugPrint(
        'AuthInterceptor: 401 Unauthorized. Triggering reactive refresh...');

    // 4. Await the refresh (single-flight mutex inside TokenManager)
    try {
      await TokenManager.refreshIfNeeded(force: true);

      // 5. Get the newly refreshed token
      final newToken = TokenManager.currentAccessToken;

      if (newToken != null && newToken.isNotEmpty) {
        debugPrint(
            'AuthInterceptor: Successfully acquired new token for retry.');

        // Update header
        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        // Mark as a retry to prevent infinite loops
        requestOptions.extra['isRetry'] = true;

        // Clone the request with the new headers
        final dio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));

        try {
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else {
        debugPrint(
            'AuthInterceptor: Refresh succeeded but token is null. Dropping request.');
        return handler.next(err);
      }
    } catch (e) {
      debugPrint(
          'AuthInterceptor: Token refresh failed via 401 reactive boundary: $e');
      await TokenManager.clear();
      return handler.next(err);
    }
  }
}
