import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileApi {
  final Dio _dio = Dio();

  ProfileApi() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception(
          'API_BASE_URL not found. Did you load .env in main.dart?');
    }

    _dio.options = BaseOptions(
      baseUrl: baseUrl, // ✅ เก็บไว้ที่นี่ที่เดียว
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
        requestBody: false,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

// API Endpoints -------------------------------------------------------
  static const _createPath = '/api/mobile/v1/profile/create';
  static const _updatePath = '/api/mobile/v1/profile/update';
  static const _listPath = '/api/mobile/v1/profile/list';
  static const _deletePath = '/api/mobile/v1/profile/delete';
// ----------------------------------------------------------------------

// Methods Create Profile -----------------------------------------------
  Future<Map<String, dynamic>> createProfile({
    required String accessToken,
    required String profileName,
    File? imageFile,
    int? profileId,
  }) async {
    final formMap = <String, dynamic>{
      if (profileId != null) 'profileId': profileId,
      'profileName': profileName,
    };

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      const allowed = {'image/jpeg', 'image/png', 'image/webp'};
      if (!allowed.contains(mimeType)) {
        throw Exception('รองรับเฉพาะ jpg, jpeg, png, webp');
      }

      formMap['file'] = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType),
      );
    }

    final formData = FormData.fromMap(formMap);

    try {
      debugPrint('UPLOAD -> ${_dio.options.baseUrl}$_createPath');
      debugPrint('TOKEN -> ${accessToken.substring(0, 20)}...');
      if (imageFile != null) {
        debugPrint('IMAGE -> ${imageFile.path}');
        debugPrint('SIZE  -> ${await imageFile.length()} bytes');
      } else {
        debugPrint('IMAGE -> (no image)');
      }

      final res = await _dio.post(
        _createPath,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Authorization': 'Bearer $accessToken'},
          validateStatus: (_) => true,
        ),
      );

      debugPrint('STATUS=${res.statusCode}');
      debugPrint('DATA=${res.data}');

      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Create profile failed: $status ${res.data}');
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

// ----------------------------------------------------------------------

// Methods Update Profile -----------------------------------------------
  Future<void> updateProfile({
    required String accessToken,
    required int profileId,
    String? profileName,
    File? imageFile,
    String? profilePictureUrl,
  }) async {
    if (imageFile != null && (profilePictureUrl?.trim().isNotEmpty ?? false)) {
      throw Exception('Send either imageFile OR profilePictureUrl, not both.');
    }

    final body = <String, dynamic>{
      'profileId': profileId,
      if (profileName?.trim().isNotEmpty ?? false)
        'profileName': profileName!.trim(),
      if (profilePictureUrl?.trim().isNotEmpty ?? false)
        'profilePicture': profilePictureUrl!.trim(),
    };

    if (imageFile != null) {
      final mime = lookupMimeType(imageFile.path) ?? 'image/';
      body['file'] = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.uri.pathSegments.last,
        contentType: MediaType.parse(mime),
      );
    }

    final res = await _dio.patch(
      _updatePath,
      data: FormData.fromMap(body),
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        contentType: 'multipart/form-data',
      ),
    );
    debugPrint('UPDATE Method Debug -----------------------------');
    debugPrint('UPDATE STATUS=${res.statusCode}');
    debugPrint('UPDATE DATA=${res.data}');
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('Update failed: $status ${res.data}');
    }
  }
// ---------------------------------------------------------------------

// Methods List Profiles -----------------------------------------------
  Future<List<Map<String, dynamic>>> fetchProfiles({
    required String accessToken,
  }) async {
    debugPrint('FETCH -> ${_dio.options.baseUrl}$_listPath');
    debugPrint('TOKEN -> ${accessToken.substring(0, 20)}...');

    final res = await _dio.get(
      _listPath,
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
// ---------------------------------------------------------------------

// Methods Delete Profile -----------------------------------------------
  Future<void> deleteProfile({
    required String accessToken,
    required int profileId,
  }) async {
    debugPrint(
        'DELETE -> ${_dio.options.baseUrl}$_deletePath?profileId=$profileId');

    final res = await _dio.delete(
      _deletePath,
      queryParameters: {'profileId': profileId},
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('Delete failed: $status ${res.data}');
    }
  }
}
