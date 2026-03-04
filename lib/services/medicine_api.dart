import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:medibuddy/Model/medicine_model.dart';
import 'token_manager.dart';
import 'custom_http_client.dart'; // Import CustomHttpClient

class MedicineApi {
  MedicineApi({dio.Dio? client, http.Client? httpClient})
      : _dio = client ?? dio.Dio(),
        _httpClient = httpClient ?? CustomHttpClient();

  final dio.Dio _dio;
  final http.Client _httpClient;

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
    final token = await TokenManager.getValidAccessToken();
    if (token != null && token.isNotEmpty) return token;

    throw Exception('No access token. Please login again.');
  }

  // ----- Medicine APIs -----
  Future<Map<String, dynamic>> addMedicineToProfile({
    required int profileId,
    int? mediId,
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

//--------------- ยาในระบบ (Medicine Catalog) ---------------
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

    final uri = Uri.parse('$_baseUrl/api/mobile/v1/medicine/list')
        .replace(queryParameters: params);

    final resp = await _httpClient.get(
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
      // ✅ keep parsing keys like before

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

// ----- list รายการยาใน profile -----
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

    final resp = await _httpClient.get(
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
      final mediListId = _readInt(item['mediListId'] ?? item['id']);

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

      final type = _readString(
        item['mediType'] ?? (med is Map ? med['mediType'] : null),
      );

      return MedicineItem(
        mediListId: mediListId,
        id: id.isNotEmpty ? id : mediId.toString(),
        nickname_medi: nickname.isNotEmpty ? nickname : official,
        officialName_medi: official,
        imagePath: imagePath,
        mediType: type.isNotEmpty ? type : null,
      );
    }).toList();
  }

  Future<MedicineDetail> getMedicineDetail({
    required int mediId,
    String? accessToken,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    // Use passed token or fetch from global/service
    accessToken ??= await _getAccessToken();

    final baseNormalized = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;

    final uri = Uri.parse('$baseNormalized/api/mobile/v1/medicine/detail')
        .replace(queryParameters: {'mediId': mediId.toString()});

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final res = await _httpClient.get(uri, headers: headers);
    final body = res.body;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body.isNotEmpty
          ? 'HTTP ${res.statusCode}: $body'
          : 'HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final medicineJson = decoded['medicine'] as Map<String, dynamic>;
    return MedicineDetail.fromJson(medicineJson);
  }

  Future<Map<String, dynamic>> updateMedicineListItem({
    required int mediListId,
    int? mediId,
    String? mediNickname,
    File? pictureFile,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final accessToken = await _getAccessToken();
    final url = '$_baseUrl/api/mobile/v1/medicine-list/update';

    // ✅ สร้าง FormData ชุดเดียว
    final formMap = <String, dynamic>{
      'mediListId': mediListId,
      'mediId':
          mediId, // ✅ ส่ง mediId เสมอ (ถ้า null คือ unlink, ถ้ามีค่าคือ link ใหม่)
      if (mediNickname != null) 'mediNickname': mediNickname.trim(),
    };

    if (pictureFile != null) {
      final mimeType = lookupMimeType(pictureFile.path) ?? 'image/jpeg';
      const allowed = {'image/jpeg', 'image/png', 'image/webp'};
      if (!allowed.contains(mimeType)) {
        throw Exception('รองรับเฉพาะ jpg, jpeg, png, webp');
      }

      formMap['picture'] = await dio.MultipartFile.fromFile(
        pictureFile.path,
        filename: p.basename(pictureFile.path),
        contentType: MediaType.parse(mimeType),
      );
    }

    final formData = dio.FormData.fromMap(formMap);

    debugPrint('✏️ UPDATE(MED) -> $url');
    debugPrint('🧾 FIELDS -> mediListId=$mediListId mediId=$mediId '
        'mediNickname=${(mediNickname ?? "").trim().isEmpty ? "(no change)" : mediNickname!.trim()}');

    debugPrint('🖼️ PICTURE -> ${pictureFile?.path ?? "(no change)"}');

    final res = await _dio.patch(
      url,
      data: formData,
      options: dio.Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        // ✅ อย่าตั้ง Content-Type เอง ให้ Dio ใส่ boundary ให้
        validateStatus: (_) => true,
      ),
    );

    debugPrint('✅ STATUS=${res.statusCode}');
    debugPrint('✅ DATA=${res.data}');

    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('Update medicine failed: $status ${res.data}');
    }

    if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
    return {'data': res.data};
  }

  Future<void> deleteMedicineListItem({
    required int mediListId,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is empty. Check your .env');
    }

    final accessToken = await _getAccessToken();

    try {
      final url = '$_baseUrl/api/mobile/v2/medicine-list/delete';

      debugPrint('🗑️ DELETE(MED) -> $url?mediListId=$mediListId');
      debugPrint('🔑 TOKEN -> ${accessToken.substring(0, 20)}...');

      final res = await _dio.delete(
        url,
        data: {
          'mediListId': mediListId,
          'confirmation': 'CONFIRM', // ✅ ตาม Requirement ใหม่
        },
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          validateStatus: (_) => true,
        ),
      );

      debugPrint('✅ STATUS=${res.statusCode}');
      debugPrint('✅ DATA=${res.data}');

      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Delete medicine failed: $status ${res.data}');
      }
    } on dio.DioException catch (e) {
      debugPrint('❌ DIO ERROR (DELETE MEDICINE)');
      debugPrint('type     = ${e.type}');
      debugPrint('message  = ${e.message}');
      debugPrint('status   = ${e.response?.statusCode}');
      debugPrint('response = ${e.response?.data}');
      rethrow;
    }
  }
}
