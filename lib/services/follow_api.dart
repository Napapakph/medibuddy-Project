import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// สำหรับติดต่อกับ Follow API
// DIO คือไลบรารี HTTP ที่ใช้ในการส่งคำขอไปยัง API
class FollowApi {
  final Dio _dio = Dio();

// สร้างอินสแตนซ์ของ FollowApi
  FollowApi() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception(
          'API_BASE_URL not found. Did you load .env in main.dart?');
    }
// กำหนดค่าเริ่มต้นของ Dio
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
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  static const _invitePath = '/api/mobile/v1/follow/invite';
  static const _followersPath = '/api/mobile/v1/follow/followers';
  static const _followersUpdatePath = '/api/mobile/v1/follow/followers/update';
  static const _followersRemovePath = '/api/mobile/v1/follow/followers/remove';
  static const _invitesPath = '/api/mobile/v1/follow/invites';
  static const _invitesAcceptPath = '/api/mobile/v1/follow/invites/accept';
  static const _invitesRejectPath = '/api/mobile/v1/follow/invites/reject';
  static const _followingPath = '/api/mobile/v1/follow/following';
  static const _followingDetailPath = '/api/mobile/v1/follow/following/detail';
  static const _followingLogsPath = '/api/mobile/v1/follow/following/logs';
  static const _followingRemovePath = '/api/mobile/v1/follow/following/remove';
  static const _searchUserPath = '/api/mobile/v1/follow/search-user';

  Options _authOptions(String accessToken) => Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        validateStatus: (_) => true,
      );

  static List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      const listKeys = [
        'data',
        'items',
        'list',
        'results',
        'followers',
        'following',
        'invites',
        'users',
      ];
      for (final key in listKeys) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      const singleKeys = ['user', 'target', 'profile'];
      for (final key in singleKeys) {
        final value = map[key];
        if (value is Map) {
          return [Map<String, dynamic>.from(value)];
        }
      }

      if (map.containsKey('id') ||
          map.containsKey('profileName') ||
          map.containsKey('email')) {
        return [map];
      }
    }

    return [];
  }

  static Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'data': data};
  }

  static void _ensureSuccess(Response res, String label) {
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('$label: $status ${res.data}');
    }
  }

// ค้นหาผู้ใช้ โดยใช้อีเมล เพื่อค้นหาผู้ติดตามหรือผู้ที่กำลังติดตาม
  Future<List<Map<String, dynamic>>> searchUsers({
    required String accessToken,
    required String email,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return [];

    final res = await _dio.get(
      _searchUserPath,
      queryParameters: {'query': trimmed},
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Search users failed');
    if (res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final users = map['users'];
      if (users is List) {
        final mapped = users
            .map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              if (item is String && item.trim().isNotEmpty) {
                return {'email': item.trim()};
              }
              return <String, dynamic>{};
            })
            .where((item) => item.isNotEmpty)
            .toList();
        if (mapped.isNotEmpty) return mapped;
      }
    }
    return _extractList(res.data);
  }

  Future<Map<String, dynamic>> sendInvite({
    required String accessToken,
    required List<int> profileIds,
    String? email,
    int? userId,
    String? name,
    File? imageFile,
  }) async {
    if ((email == null || email.trim().isEmpty) &&
        (userId == null || userId <= 0)) {
      throw Exception('Missing invite target');
    }

    final Map<String, dynamic> body = {
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (userId != null && userId > 0) 'userId': userId,
      'profileIds': profileIds,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    };

    dynamic data = body;
    Options options = _authOptions(accessToken);

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      body['accountPicture'] = await MultipartFile.fromFile(
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );
      data = FormData.fromMap(body);
      options = Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        contentType: 'multipart/form-data',
        validateStatus: (_) => true,
      );
    }

    final res = await _dio.post(
      _invitePath,
      data: data,
      options: options,
    );
    _ensureSuccess(res, 'Send invite failed');
    return _extractMap(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchFollowers({
    required String accessToken,
  }) async {
    final res = await _dio.get(
      _followersPath,
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Fetch followers failed');
    return _extractList(res.data);
  }

  Future<void> updateFollowerProfiles({
    required String accessToken,
    required int relationshipId,
    required List<int> profileIds,
    String? name,
  }) async {
    final body = <String, dynamic>{
      'profileIds': profileIds,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    };
    final res = await _dio.patch(
      _followersUpdatePath,
      queryParameters: {'relationshipId': relationshipId},
      data: body,
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Update follower failed');
  }

  Future<void> updateFollowerNickname({
    required String accessToken,
    required int relationshipId,
    required String nickname,
    List<int> profileIds = const [],
  }) async {
    final base = <String, dynamic>{
      'relationshipId': relationshipId,
      if (profileIds.isNotEmpty) 'profileIds': profileIds,
    };

    final payloads = [
      {...base, 'name': nickname},
    ];

    Response? lastRes;
    for (final data in payloads) {
      final res = await _dio.patch(
        _followersUpdatePath,
        data: data,
        options: _authOptions(accessToken),
      );
      lastRes = res;
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        return;
      }
      if (status == 400 || status == 404) {
        continue;
      }
      throw Exception('Update follower failed: $status ${res.data}');
    }

    final status = lastRes?.statusCode ?? 0;
    throw Exception('Update follower failed: $status ${lastRes?.data}');
  }

  Future<void> updateFollower({
    required String accessToken,
    required int relationshipId,
    required String name,
    required List<int> profileIds,
    File? imageFile,
    String?
        accountPicture, // เก็บไว้เผื่อกรณีไม่ได้อัปรูปใหม่ แต่ต้องการส่ง path เดิม (ถ้า API รองรับ)
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'profileIds':
          profileIds.toString(), // แปลง List<int> เป็น String "[1, 2]"
    };

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      const allowed = {'image/jpeg', 'image/png', 'image/webp'};
      if (!allowed.contains(mimeType)) {
        throw Exception('รองรับเฉพาะ jpg, jpeg, png, webp');
      }

      body['accountPicture'] = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType),
      );
    } else if (accountPicture?.trim().isNotEmpty ?? false) {
      // กรณีไม่ได้อัปรูปใหม่ แต่ backend ต้องการค่าเดิม หรือ format อื่น
      // body['accountPicture'] = accountPicture!.trim();
      // คอมเมนต์ไว้ก่อน เพราะ User เน้นเรื่อง multipart file upload
    }

    debugPrint('UPDATE FOLLOWER Debug -----------------------------');
    debugPrint(
        'URL -> ${_dio.options.baseUrl}$_followersUpdatePath?relationshipId=$relationshipId');
    debugPrint('NAME -> ${name.trim()}');
    debugPrint('PROFILE_IDS (String) -> ${body['profileIds']}');

    try {
      final res = await _dio.patch(
        _followersUpdatePath,
        queryParameters: {'relationshipId': relationshipId},
        data: FormData.fromMap(body),
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          contentType: 'multipart/form-data',
          validateStatus: (_) => true,
        ),
      );

      debugPrint('RESPONSE STATUS=${res.statusCode}');
      debugPrint('RESPONSE DATA=${res.data}');

      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Update follower failed: $status ${res.data}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DIO ERROR: ${e.message}');
      rethrow;
    }
  }

  Future<void> removeFollower({
    required String accessToken,
    required int followerId,
  }) async {
    final res = await _dio.delete(
      _followersRemovePath,
      queryParameters: {'followerId': followerId},
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Remove follower failed');
  }

  Future<List<Map<String, dynamic>>> fetchInvites({
    required String accessToken,
  }) async {
    final res = await _dio.get(
      _invitesPath,
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Fetch invites failed');
    return _extractList(res.data);
  }

  Future<void> acceptInvite({
    required String accessToken,
    required int relationshipId,
  }) async {
    final res = await _dio.post(
      _invitesAcceptPath,
      queryParameters: {'relationshipId': relationshipId},
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Accept invite failed');
  }

  Future<void> rejectInvite({
    required String accessToken,
    required int relationshipId,
  }) async {
    final res = await _dio.post(
      _invitesRejectPath,
      queryParameters: {'relationshipId': relationshipId},
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Reject invite failed');
  }

  Future<List<Map<String, dynamic>>> fetchFollowing({
    required String accessToken,
  }) async {
    final res = await _dio.get(
      _followingPath,
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Fetch following failed');
    return _extractList(res.data);
  }

  Future<Map<String, dynamic>> fetchFollowingDetail({
    required String accessToken,
    required int relationshipId,
  }) async {
    final res = await _dio.get(
      _followingDetailPath,
      queryParameters: {'relationshipId': relationshipId},
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Fetch following detail failed');
    return _extractMap(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchFollowingLogs({
    required String accessToken,
    required int relationshipId,
    required int profileId,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    final params = <String, dynamic>{
      'relationshipId': relationshipId,
      'profileId': profileId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
    final res = await _dio.get(
      _followingLogsPath,
      queryParameters: params,
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Fetch following logs failed');

    if (res.data is Map && res.data['logs'] is List) {
      return (res.data['logs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> removeFollowing({
    required String accessToken,
    required int relationshipId,
  }) async {
    final res = await _dio.delete(
      _followingRemovePath,
      queryParameters: {'relationshipId': relationshipId},
      options: _authOptions(accessToken),
    );
    _ensureSuccess(res, 'Remove following failed');
  }
}
