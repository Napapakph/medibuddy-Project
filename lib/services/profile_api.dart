import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';

class ProfileApi {
  ProfileApi(this.baseUrl);

  final String baseUrl;
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
}
