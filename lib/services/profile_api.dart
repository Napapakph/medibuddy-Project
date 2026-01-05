import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ProfileApi {
  ProfileApi(this.baseUrl);

  final String baseUrl;
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> createProfile({
    required String accessToken,
    required String profileName,
    required File imageFile,
    int? profileId, // ส่งเฉพาะกรณี backend บังคับ
  }) async {
    final mimeType = lookupMimeType(imageFile.path) ?? '';
    if (!mimeType.startsWith('image/')) {
      throw Exception('ไฟล์ต้องเป็นรูปภาพเท่านั้น');
    }

    // อนุญาตเฉพาะ jpg/jpeg/png/webp ตามที่เดียร์ต้องการ
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowed.contains(mimeType)) {
      throw Exception('รองรับเฉพาะ jpg, jpeg, png, webp');
    }

    final formData = FormData.fromMap({
      if (profileId != null) 'profileId': profileId.toString(),
      'profileName': profileName,
      'profilePicture': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType),
      ),
    });

    final res = await _dio.post(
      'http://82.26.104.199:3000/api/mobile/v1/profile/create',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Authorization': 'Bearer $accessToken'},
        validateStatus: (_) => true, // ถ้ามี token
      ),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Create profile failed: ${res.statusCode} ${res.data}');
    }

    // คาดว่า backend ส่ง JSON กลับมา
    return Map<String, dynamic>.from(res.data as Map);
  }
}
