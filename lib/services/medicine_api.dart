import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medibuddy/Model/medicine_model.dart';

class MedicineApi {
  MedicineApi();

  final _supabase = Supabase.instance.client;

  String get _baseUrl => (dotenv.env['API_BASE_URL'] ?? '').trim();

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<String> _getAccessToken() async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) return token;
    throw Exception('No access token. Please login again.');
  }

  /// POST /api/admin/v1/medicine-list/create
  /// multipart/form-data:
  /// - profileId (required)
  /// - mediId (required)
  /// - mediNickname (optional)
  /// - picture (optional binary)
  Future<void> addMedicineToProfile({
    required int profileId,
    required int mediId,
    String? mediNickname,
    File? pictureFile,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final token = await _getAccessToken();

    final uri = Uri.parse('$_baseUrl/api/admin/v1/medicine-list/create');
    final req = http.MultipartRequest('POST', uri);

    // headers
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';

    // fields (ต้องเป็น string)
    req.fields['profileId'] = profileId.toString();
    req.fields['mediId'] = mediId.toString();

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

  /// GET /api/admin/v1/medicine/list
  Future<List<MedicineCatalogItem>> fetchMedicineCatalog({
    String search = '',
    int page = 1,
    int pageSize = 50,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final token = await _getAccessToken();
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'order': 'A-Z',
      'includeDeleted': 'false',
    };

    final trimmed = search.trim();
    if (trimmed.isNotEmpty) {
      params['search'] = trimmed;
    }

    final uri = Uri.parse('$_baseUrl/api/admin/v1/medicine/list')
        .replace(queryParameters: params);

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        resp.body.isNotEmpty ? resp.body : 'HTTP ${resp.statusCode}',
      );
    }

    final data = jsonDecode(resp.body);
    final items = data is Map<String, dynamic>
        ? (data['items'] ?? data['data'])
        : data is List
            ? data
            : null;
    if (items is! List) return [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(MedicineCatalogItem.fromJson)
        .toList();
  }

  /// GET /api/admin/v1/medicine-list/list?profileId=...
  Future<List<MedicineItem>> fetchProfileMedicineList({
    required int profileId,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final token = await _getAccessToken();
    final uri = Uri.parse('$_baseUrl/api/admin/v1/medicine-list/list').replace(
      queryParameters: {
        'profileId': profileId.toString(),
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        resp.body.isNotEmpty ? resp.body : 'HTTP ${resp.statusCode}',
      );
    }

    final data = jsonDecode(resp.body);
    final items = data is Map<String, dynamic>
        ? (data['items'] ?? data['data'])
        : data is List
            ? data
            : null;
    if (items is! List) return [];

    return items.whereType<Map<String, dynamic>>().map((item) {
      final mediId = _readInt(
        item['mediId'] ?? item['medId'] ?? item['medicineId'],
      );
      final id = _readString(item['id']);
      final nickname = _readString(
        item['mediNickname'] ?? item['nickname'] ?? item['displayName'],
      );
      final tradeName = _readString(item['mediTradeName']);
      final enName = _readString(item['mediEnName']);
      final thName = _readString(item['mediThName']);
      final official = tradeName.isNotEmpty
          ? tradeName
          : enName.isNotEmpty
              ? enName
              : thName;
      final imagePath = _readString(
        item['picture'] ??
            item['imageUrl'] ??
            item['image'] ??
            item['mediPicture'],
      );

      return MedicineItem(
        id: id.isNotEmpty ? id : mediId.toString(),
        nickname_medi: nickname.isNotEmpty ? nickname : official,
        officialName_medi: official,
        imagePath: imagePath,
      );
    }).toList();
  }
}
