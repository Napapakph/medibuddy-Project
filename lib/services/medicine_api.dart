import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineApi {
  MedicineApi();

  final _supabase = Supabase.instance.client;

  String get _baseUrl => (dotenv.env['API_BASE_URL'] ?? '').trim();

  Future<String> _getAccessToken() async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) return token;
    throw Exception('No access token. Please login again.');
  }

  /// POST /api/mobile/v1/medicine-list/create
  /// multipart/form-data:
  /// - profileId (required)
  /// - medId (required)
  /// - mediNickname (optional)
  /// - picture (optional binary)
  Future<void> addMedicineToProfile({
    required int profileId,
    required int medId,
    String? mediNickname,
    File? pictureFile,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final token = await _getAccessToken();

    final uri = Uri.parse('$_baseUrl/api/mobile/v1/medicine-list/create');
    final req = http.MultipartRequest('POST', uri);

    // headers
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';

    // fields (ต้องเป็น string)
    req.fields['profileId'] = profileId.toString();
    req.fields['medId'] = medId.toString();

    if (mediNickname != null && mediNickname.trim().isNotEmpty) {
      req.fields['mediNickname'] = mediNickname.trim();
    }

    // file (optional)
    if (pictureFile != null) {
      final fileName = p.basename(pictureFile.path);

      // เดา content-type แบบง่าย ๆ (กัน server งอแง)
      final ext = p.extension(fileName).toLowerCase();
      MediaType contentType = MediaType('image', 'jpeg');
      if (ext == '.png') contentType = MediaType('image', 'png');
      if (ext == '.webp') contentType = MediaType('image', 'webp');

      req.files.add(
        await http.MultipartFile.fromPath(
          'picture',
          pictureFile.path,
          filename: fileName,
          contentType: contentType,
        ),
      );
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    // ปรับตาม backend คุณได้ (บางที 200/201)
    if (resp.statusCode == 200 || resp.statusCode == 201) return;

    // พยายามอ่าน error message จาก json
    try {
      final data = jsonDecode(resp.body);
      throw Exception(data['message'] ?? resp.body);
    } catch (_) {
      throw Exception(
          resp.body.isNotEmpty ? resp.body : 'HTTP ${resp.statusCode}');
    }
  }
}
