import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'package:medibuddy/Model/medicine_model.dart';

class MedicineApi {
  MedicineApi({dio.Dio? client}) : _dio = client ?? dio.Dio();

  final dio.Dio _dio;
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

  /// POST /api/mobile/v1/medicine-list/create
  /// multipart/form-data:
  /// - profileId (required)
  /// - mediId (required)
  /// - mediNickname (optional)
  /// - picture (optional binary)  ✅ FIELD_NAME MUST BE "picture"
  ///
  /// ✅ Style: same as ProfileApi (Dio + FormData + logs + validateStatus)
  Future<Map<String, dynamic>> addMedicineToProfile({
    required int profileId,
    required int mediId,
    String? mediNickname,
    File? pictureFile,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final accessToken = await _getAccessToken();

    final formMap = <String, dynamic>{
      'profileId': profileId,
      'mediId': mediId,
      if (mediNickname != null && mediNickname.trim().isNotEmpty)
        'mediNickname': mediNickname.trim(),
    };

    if (pictureFile != null) {
      final mimeType = lookupMimeType(pictureFile.path) ?? 'image/jpeg';

      // ✅ same policy style as profile upload
      const allowed = {'image/jpeg', 'image/png', 'image/webp'};
      if (!allowed.contains(mimeType)) {
        throw Exception('รองรับเฉพาะ jpg, jpeg, png, webp');
      }

      formMap['picture'] = await dio.MultipartFile.fromFile(
        pictureFile.path,
        filename: p.basename(pictureFile.path),
        contentType: MediaType.parse(mimeType),
      ); // ✅ DIO MultipartFile
    }

    final formData = dio.FormData.fromMap(formMap);

    try {
      final url = '$_baseUrl/api/mobile/v1/medicine-list/create';

      debugPrint('💊 UPLOAD(MED) -> $url');
      debugPrint('🔑 TOKEN -> ${accessToken.substring(0, 20)}...');
      debugPrint('🧾 FIELDS -> profileId=$profileId mediId=$mediId '
          'mediNickname=${(mediNickname ?? "").trim().isEmpty ? "(none)" : mediNickname!.trim()}');

      if (pictureFile != null) {
        debugPrint('🖼️ PICTURE -> ${pictureFile.path}');
        debugPrint('📦 SIZE    -> ${await pictureFile.length()} bytes');
      } else {
        debugPrint('🖼️ PICTURE -> (no picture)');
      }

      final res = await _dio.post(
        url,
        data: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
          headers: {'Authorization': 'Bearer $accessToken'},
          validateStatus: (_) => true,
        ),
      );

      debugPrint('✅ STATUS=${res.statusCode}');
      debugPrint('✅ DATA=${res.data}');

      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Add medicine failed: $status ${res.data}');
      }

      // ✅ return map (so caller can read server path เช่น /uploads/medicine_database/...)
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }

      // backend บางทีส่ง string/array -> wrap ให้เป็น map
      return {'data': res.data};
    } on dio.DioException catch (e) {
      debugPrint('❌ DIO ERROR (MEDICINE)');
      debugPrint('type     = ${e.type}');
      debugPrint('message  = ${e.message}');
      debugPrint('status   = ${e.response?.statusCode}');
      debugPrint('response = ${e.response?.data}');
      rethrow;
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
          resp.body.isNotEmpty ? resp.body : 'HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);

    final dynamic itemsDynamic = data is Map<String, dynamic>
        ? (data['items'] ?? data['data'])
        : (data is List ? data : null);

    if (itemsDynamic is! List) return [];

    String normalizeServerPath(String raw) {
      final p = raw.trim();
      if (p.isEmpty || p.toLowerCase() == 'null') return '';

      // ✅ full URL ที่ถูกต้องเท่านั้น
      if (p.startsWith('http://') || p.startsWith('https://')) return p;

      // ✅ บังคับให้ path เป็น absolute เสมอ
      if (p.startsWith('/')) return p;

      return '/$p';
    }

    // ✅ DEBUG: print only first 3 items for readability
    final sampleCount = itemsDynamic.length < 3 ? itemsDynamic.length : 3;
    for (int i = 0; i < sampleCount; i++) {
      final row = itemsDynamic[i];
      if (row is! Map) continue;

      final mediId = row['mediId'];
      final thName = row['mediThName'];
      final enName = row['mediEnName'];
      final tradeName = row['mediTradeName'];

      final rawPic = (row['mediPicture'] ??
              row['imageUrl'] ??
              row['imagePath'] ??
              row['picture'] ??
              '')
          .toString();

      final normalized = normalizeServerPath(rawPic);
      final fullUrl =
          (normalized.startsWith('http')) ? normalized : '$_baseUrl$normalized';

      debugPrint(
          '🧪 CATALOG[$i] mediId=$mediId th="$thName" en="$enName" trade="$tradeName"');
      debugPrint(
          '🧪 CATALOG[$i] rawPic="$rawPic" normalized="$normalized" fullUrl="$fullUrl"');
    }

    return itemsDynamic
        .whereType<Map<String, dynamic>>()
        .map(MedicineCatalogItem.fromJson)
        .toList();
  }

  /// GET /api/mobile/v1/medicine-list/list?profileId=...
  Future<List<MedicineItem>> fetchProfileMedicineList({
    required int profileId,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final token = await _getAccessToken();

    final uri = Uri.parse('$_baseUrl/api/mobile/v1/medicine-list/list').replace(
      queryParameters: {'profileId': profileId.toString()},
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
          resp.body.isNotEmpty ? resp.body : 'HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final items = data is Map<String, dynamic>
        ? (data['items'] ?? data['data'])
        : data is List
            ? data
            : null;

    if (items is! List) return [];

    return items.whereType<Map<String, dynamic>>().map((item) {
      final mediId =
          _readInt(item['mediId'] ?? item['medId'] ?? item['medicineId']);

      final id = _readString(item['id']);
      final nickname = _readString(
          item['mediNickname'] ?? item['nickname'] ?? item['displayName']);

      final tradeName = _readString(item['mediTradeName']);
      final enName = _readString(item['mediEnName']);
      final thName = _readString(item['mediThName']);

      final official = tradeName.isNotEmpty
          ? tradeName
          : enName.isNotEmpty
              ? enName
              : thName;

      // ✅ keep parsing keys like before
      final med = item['medicine'];
      final imagePath = _readString(
        item['pictureOption'] ??
            item['picture'] ??
            item['imageUrl'] ??
            item['image'] ??
            item['mediPicture'] ??
            (med is Map
                ? (med['mediPicture'] ?? med['imageUrl'] ?? med['picture'])
                : null),
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
