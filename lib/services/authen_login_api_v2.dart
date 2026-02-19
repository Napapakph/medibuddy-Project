import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'auth_manager.dart'; // Import AuthManager

class CustomAuthService implements AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  CustomAuthService() {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isNotEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    // Add interceptor for token injection and refresh logic could be added here
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Try getting from memory first (faster)
        var token = AuthManager.accessToken;

        // If not in memory, try storage
        if (token == null) {
          token = await _storage.read(key: _accessTokenKey);
          if (token != null) AuthManager.accessToken = token; // Cache it
        }

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // simple handling: avoid infinite loop
          if (e.requestOptions.path.contains('/refresh')) {
            return handler.next(e);
          }

          // Try refresh
          try {
            final newToken = await _refreshTokenInternal();
            if (newToken != null) {
              // Retry original request
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              return handler.resolve(await _dio.fetch(e.requestOptions));
            }
          } catch (_) {
            // Refresh failed
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<String?> _refreshTokenInternal() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final res = await _dio.post('/api/auth/v2/refresh', data: {
        'refreshToken': refreshToken,
      });
      final accessToken = res.data['accessToken'];
      if (accessToken != null) {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        AuthManager.accessToken = accessToken; // ✅ Update Global
        return accessToken;
      }
    } catch (e) {
      // Clear tokens if refresh fails?
      AuthManager.accessToken = null; // Clear Global
      // await logout();
    }
    return null;
  }

  @override
  Future<String?> register(
      {required String email, required String password}) async {
    try {
      await _dio.post('/api/auth/v2/register', data: {
        'email': email,
        'password': password,
      });
      return null; // Success
    } on DioException catch (e) {
      return e.response?.data?['message'] ?? e.message ?? 'Registration failed';
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }

  @override
  Future<AuthResponse> login(
      {required String email, required String password}) async {
    try {
      final res = await _dio.post('/api/auth/v2/login', data: {
        'email': email,
        'password': password,
      });

      final data = res.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken != null) {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        AuthManager.accessToken = accessToken; // ✅ Set Global
      }
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }

      return AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: data['user'],
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data?['message'] ?? 'Login failed');
      }
      throw Exception('Connection error');
    }
  }

  @override
  Future<AuthResponse> verifyOtp(
      {required String email, required String token}) async {
    try {
      final res = await _dio.post('/api/auth/v2/otp/verify', data: {
        'email': email,
        'code': token,
      });

      final data = res.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken != null) {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        AuthManager.accessToken = accessToken; // ✅ Set Global
      }
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }

      return AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: data['user'],
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'OTP Verification failed');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post('/api/auth/v2/logout', data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (_) {}
    await _storage.deleteAll();
    AuthManager.accessToken = null; // ✅ Clear Global Variable
  }

  @override
  Future<String?> refreshToken() async {
    return _refreshTokenInternal();
  }

  @override
  Future<String> checkEmailStatus(String email) async {
    // V2 doesn't have check-email, assume 'new' to proceed to register
    // or we could implementation V1 check here if desired.
    // For now returning 'new' to let register handle it.
    return 'new';
  }

  @override
  Future<void> resendOtp(String email) async {
    // Not defined in user request, possibly not supported or uses register endpoint again?
    // Throw unimplemented or just ignore for now.
    // Or maybe just call register again?
    // await register(email: email, password: "..."); // We don't have password here.

    // Throwing exception to notify UI
    throw Exception('Resend OTP not supported in V2 yet');
  }

  @override
  Future<void> signInWithGoogle() async {
    // Custom API Google Sign-In needs implementation details (e.g. backend endpoint)
    throw Exception('Google Sign-In not supported in Custom API yet');
  }

  @override
  Future<String?> getAccessToken() async {
    // Check global cache first
    if (AuthManager.accessToken != null) return AuthManager.accessToken;

    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      AuthManager.accessToken = token; // Sync back to global
      print(
          '🔑 [CustomAPI] getAccessToken: Found (${token.substring(0, 5)}...)');
    } else {
      print('⚠️ [CustomAPI] getAccessToken: Not found');
    }
    return token;
  }
}
