import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart'; // ✅ Import globalDeviceTokenService
import 'token_manager.dart';
import 'auth_interceptor.dart';

/// Structured result from register() to distinguish success, merge-required, and generic error.
class RegisterResult {
  final bool success;
  final bool requiresMerge;
  final String? errorMessage;
  final String? backendMessage;

  const RegisterResult.ok()
      : success = true,
        requiresMerge = false,
        errorMessage = null,
        backendMessage = null;

  const RegisterResult.error(this.errorMessage)
      : success = false,
        requiresMerge = false,
        backendMessage = null;

  const RegisterResult.merge({required this.backendMessage})
      : success = false,
        requiresMerge = true,
        errorMessage = null;
}

class CustomAuthService implements AuthService {
  final Dio _dio = Dio();

  CustomAuthService() {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isNotEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    // Register Interceptor
    _dio.interceptors.add(AuthInterceptor());
  }

  @override
  Future<String?> register(
      {required String email, required String password}) async {
    final result = await registerWithResult(email: email, password: password);
    if (result.success) return null;
    if (result.requiresMerge) return result.backendMessage;
    return result.errorMessage;
  }

  /// Structured register — surfaces 409 merge requirement.
  Future<RegisterResult> registerWithResult(
      {required String email, required String password}) async {
    try {
      await _dio.post('/api/auth/v2/register', data: {
        'email': email,
        'password': password,
      });
      return const RegisterResult.ok();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map && data['requiresMerge'] == true) {
          return RegisterResult.merge(
            backendMessage: data['message']?.toString() ??
                'อีเมลนี้เชื่อมกับบัญชี Google อยู่แล้ว',
          );
        }
      }
      return RegisterResult.error(e.response?.data?['message']?.toString() ??
          e.message ??
          'Registration failed');
    } catch (e) {
      return RegisterResult.error('เกิดข้อผิดพลาด: $e');
    }
  }

  /// Request OTP for email verification or merge flow.
  Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      final res = await _dio.post('/api/auth/v2/otp/request', data: {
        'email': email,
      });
      return Map<String, dynamic>.from(res.data ?? {});
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message']?.toString() ?? 'OTP request failed');
    }
  }

  /// Merge Google account with email/password (set password for Google-only account).
  Future<AuthResponse> registerMerge({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/api/auth/v2/register/merge', data: {
        'email': email,
        'otp': otp,
        'password': password,
      });
      final data = res.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken != null) {
        await TokenManager.setSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        globalDeviceTokenService.registerDeviceToken(force: true);
      }

      return AuthResponse(
        accessToken: accessToken ?? '',
        refreshToken: refreshToken,
        user: data['user'],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final errorCode = data is Map ? data['error']?.toString() : null;
      final msg = data is Map
          ? data['message']?.toString() ?? 'Merge failed'
          : 'Merge failed';
      throw MergeException(code: errorCode ?? 'UNKNOWN', message: msg);
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
        await TokenManager.setSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
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
        await TokenManager.setSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        globalDeviceTokenService.registerDeviceToken(
            force: true); // ✅ Push token to backend
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
      // Note: Backend logout not implemented with stored token here due to removal of storage read
      // but if a `/logout` API requires the refresh token, it should be handled before TokenManager.clear()
      await _dio.post('/api/auth/v2/logout');
    } catch (_) {}
    await TokenManager.clear();
  }

  @override
  Future<String?> refreshToken() async {
    await TokenManager.refreshIfNeeded(force: true);
    return TokenManager.currentAccessToken;
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
    await requestOtp(email);
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // ดึงค่า Web Client ID (ที่นำมาจาก Google Cloud Console) จาก .env
      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            serverClientId, // สำคัญมากสำหรับระบบที่ไม่ได้ใช้ Firebase เป็นตัวกลาง
        scopes: [
          'email',
          'profile',
        ],
      );

      // ✅ สั่ง Sign Out ก่อนทุกครั้ง เพื่อล้างแคชบัญชีเก่า
      // วิธีนี้จะบังคับให้ Google เด้งหน้าต่างเลือกบัญชีมาใหม่เสมอ!
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('ยกเลิกการเข้าสู่ระบบ'); // User canceled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        // บางกรณี Google ไม่ยอมคาย idToken ต้องกำหนด clientId/serverClientId แบบเฉพาะเจาะจง
        throw Exception('ไม่ได้รับ idToken จาก Google');
      }

      // ส่ง idToken ไปยัง Backend API
      final res = await _dio.post(
        '/api/auth/v2/google-login',
        data: {
          'idToken': idToken,
        },
      );

      final data = res.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken != null) {
        await TokenManager.setSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        globalDeviceTokenService.registerDeviceToken(
            force: true); // ✅ Push token to backend
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data?['message'] ?? 'Google Login failed on server');
      }
      throw Exception('Connection error');
    } catch (e) {
      throw Exception('Google Login Error: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final token = await TokenManager.getValidAccessToken();
    if (token != null) {
      print(
          '🔑 [CustomAPI] getAccessToken: Found (${token.substring(0, 5)}...)');
    } else {
      print('⚠️ [CustomAPI] getAccessToken: Not found');
    }
    return token;
  }

  // ==== ฟังก์ชันลืมรหัสผ่านด้วย API ====
  Future<void> requestPasswordReset(String email, String redirectTo) async {
    try {
      await _dio.post('/api/auth/v2/forgot-password/request', data: {
        'email': email,
        'redirectTo': redirectTo,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data?['message'] ?? 'Request password reset failed');
      }
      throw Exception('Connection error');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post('/api/auth/v2/forgot-password/reset', data: {
        'token': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data?['message'] ?? 'Reset password failed');
      }
      throw Exception('Connection error');
    }
  }
}

/// Typed exception for merge API errors.
class MergeException implements Exception {
  final String code;
  final String message;
  const MergeException({required this.code, required this.message});

  @override
  String toString() => 'MergeException($code): $message';
}
