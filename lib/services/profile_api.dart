import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';

class ProfileApi {
  final String baseUrl;
  //ตั้ง timeout ใน constructor
  ProfileApi(this.baseUrl) {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      validateStatus: (_) => true,
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: false, // multipart ยาว ปิดไว้
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  final Dio _dio = Dio();

  Future<Map<String, dynamic>> createProfile({
    required String accessToken,
    required String profileName,
    required File imageFile,
    int? profileId,
  }) async {
    final mimeType = lookupMimeType(imageFile.path) ?? '';
    if (!mimeType.startsWith('image/')) {
      throw Exception('ไฟล์ต้องเป็นรูปภาพเท่านั้น');
    }

    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowed.contains(mimeType)) {
      throw Exception('รองรับเฉพาะ jpg, jpeg, png, webp');
    }

    final formData = FormData.fromMap({
      if (profileId != null) 'profileId': profileId.toString(),
      'profileName': profileName,
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType),
      ),
    });

    try {
      debugPrint('UPLOAD -> $baseUrl/api/mobile/v1/profile/create');
      debugPrint('TOKEN -> ${accessToken.substring(0, 20)}...');
      debugPrint('IMAGE -> ${imageFile.path}');
      debugPrint('SIZE  -> ${await imageFile.length()} bytes');

      final res = await _dio.post(
        '$baseUrl/api/mobile/v1/profile/create',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
          validateStatus: (_) => true,
        ),
      );

      debugPrint('STATUS=${res.statusCode}');
      debugPrint('DATA=${res.data}');

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(
          'Create profile failed: ${res.statusCode} ${res.data}',
        );
      }

      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      debugPrint('❌ DIO ERROR');
      debugPrint('type     = ${e.type}');
      debugPrint('message  = ${e.message}');
      debugPrint('status   = ${e.response?.statusCode}');
      debugPrint('response = ${e.response?.data}');
      rethrow;
    }
  }

  // API สำหรับอัพเดทรูปโปรไฟล์
  Future<void> updateProfile({
    required String accessToken,
    required String profileId, // PROFILE_ID
    required String profileName, // PROFILE_NAME
    File? imageFile, // ถ้ามีค่อยส่ง
  }) async {
    final formData = FormData.fromMap({
      'profileId': profileId,
      'profileName': profileName,
      if (imageFile != null)
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.uri.pathSegments.last,
          contentType:
              MediaType.parse(lookupMimeType(imageFile.path) ?? 'image/jpeg'),
        ),
    });

    final res = await _dio.put(
      '/api/mobile/v1/profile/update',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        contentType: 'multipart/form-data',
        validateStatus: (_) => true,
      ),
    );

    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('Update failed: $status ${res.data}');
    }
  }

  //API สำหรับดึง list Profile

  Future<List<Map<String, dynamic>>> fetchProfiles({
    required String accessToken,
  }) async {
    debugPrint('FETCH -> $baseUrl/api/mobile/v1/profile/list');
    debugPrint('TOKEN -> ${accessToken.substring(0, 20)}...');

    final res = await _dio.get(
      '/api/mobile/v1/profile/list',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    debugPrint('STATUS=${res.statusCode}');
    debugPrint('DATA=${res.data}');

    if (res.statusCode != 200) {
      throw Exception('Fetch profiles failed: ${res.statusCode} ${res.data}');
    }

    final data = res.data;

    // รองรับทั้งกรณี backend คืน {profiles:[...]} หรือคืน [...] ตรงๆ
    if (data is Map && data['profiles'] is List) {
      return (data['profiles'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    throw Exception('Unexpected response shape: $data');
  }
  //API สำหรับลบ Profile

  Future<void> deleteProfile({
    required String accessToken,
    required String profileId,
  }) async {
    final url = Uri.parse('$baseUrl/api/mobile/v1/profile/delete');
    debugPrint(
        'DELETE -> $baseUrl/api/mobile/v1/profile/delete?profileId=$profileId');

    final res = await _dio.delete(
      '/api/mobile/v1/profile/delete',
      queryParameters: {'profileId': profileId},
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        validateStatus: (_) => true,
      ),
    );
    debugPrint('STATUS=${res.statusCode}');
    debugPrint('DATA=${res.data}');
    debugPrint('HEADERS=${res.headers.map}');

    final status = res.statusCode ?? 0;

    if (status < 200 || status >= 300) {
      throw Exception('Delete failed: $status ${res.data}');
    }
  }
}
