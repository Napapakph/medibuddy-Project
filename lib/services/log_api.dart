import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_manager.dart'; // Import

class LogApiException implements Exception {
  final String message;
  final int? statusCode;

  LogApiException(this.message, {this.statusCode});

  @override
  String toString() => 'LogApiException($statusCode): $message';
}

class LogApiService {
  LogApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();
  final http.Client _client;

  String _baseUrl() {
    final base = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (base.isEmpty) {
      throw LogApiException('API_BASE_URL is missing in .env');
    }
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Future<String> _getAccessToken() async {
    // Check global
    if (AuthManager.accessToken != null) return AuthManager.accessToken!;

    // Check service
    final token = await AuthManager.service.getAccessToken();
    if (token != null && token.isNotEmpty) return token;

    throw LogApiException('Please login again (missing access token).');
  }

  Future<List<Map<String, dynamic>>> getMedicationLogs({
    required int profileId,
    String? accessToken,
  }) async {
    if (profileId <= 0) {
      throw LogApiException('profileId must be a positive integer.');
    }

    accessToken ??= await _getAccessToken();
    final url = Uri.parse(
      '${_baseUrl()}/api/mobile/v1/medication-log/list?profileId=$profileId',
    );

    debugPrint('medication-log list profileId=$profileId');

    final res = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('medication-log list status=${res.statusCode}');
    debugPrint('medication-log list body length=${res.body.length}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      throw LogApiException(
        message ?? 'Get medication logs failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final logs = await compute(_decodeMedicationLogs, res.body);
    return logs;
  }

  Future<Map<String, dynamic>> getMedicationLogDetail({
    required int logId,
    String? accessToken,
  }) async {
    if (logId <= 0) {
      throw LogApiException('logId must be a positive integer.');
    }

    accessToken ??= await _getAccessToken();
    final url = Uri.parse('${_baseUrl()}/api/mobile/v1/medication-log/$logId');

    debugPrint('medication-log detail logId=$logId');

    final res = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('medication-log detail status=${res.statusCode}');
    debugPrint('medication-log detail body length=${res.body.length}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      throw LogApiException(
        message ?? 'Get medication log detail failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map) {
      if (decoded['log'] is Map) {
        return Map<String, dynamic>.from(decoded['log'] as Map);
      }
      if (decoded['data'] is Map) {
        final data = decoded['data'] as Map;
        if (data['log'] is Map) {
          return Map<String, dynamic>.from(data['log'] as Map);
        }
        return Map<String, dynamic>.from(data);
      }
      return Map<String, dynamic>.from(decoded);
    }

    throw LogApiException('Invalid response format (expected object).');
  }

  Future<void> submitMedicationLogResponse({
    required int logId,
    required String responseStatus,
    String? note,
    String? accessToken,
  }) async {
    if (logId <= 0) {
      throw LogApiException('logId must be a positive integer.');
    }

    accessToken ??= await _getAccessToken();
    final url =
        Uri.parse('${_baseUrl()}/api/mobile/v1/medication-log/response');

    final trimmedNote = note?.trim();
    final body = <String, dynamic>{
      'logId': logId,
      'responseStatus': responseStatus,
    };
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      body['note'] = trimmedNote;
    }

    debugPrint('medication-log response request=${jsonEncode(body)}');

    final res = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    debugPrint('medication-log response status=${res.statusCode}');
    debugPrint('medication-log response body length=${res.body.length}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      throw LogApiException(
        message ?? 'Submit medication response failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
  }

  String? _friendlyAuthError(int statusCode) {
    if (statusCode == 401) return 'Unauthorized. Please login again.';
    if (statusCode == 403) return 'Not allowed.';
    return null;
  }

  String? _readErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['error'] != null) return decoded['error'].toString();
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }
}

List<Map<String, dynamic>> _decodeMedicationLogs(String body) {
  final decoded = jsonDecode(body);
  dynamic logsRaw;
  if (decoded is Map) {
    if (decoded['logs'] is List) {
      logsRaw = decoded['logs'];
    } else if (decoded['data'] is Map) {
      final data = decoded['data'] as Map;
      if (data['logs'] is List) {
        logsRaw = data['logs'];
      }
    } else if (decoded['data'] is List) {
      logsRaw = decoded['data'];
    }
  } else if (decoded is List) {
    logsRaw = decoded;
  }

  if (logsRaw is! List) return [];

  final result = <Map<String, dynamic>>[];
  for (final item in logsRaw) {
    if (item is Map) {
      result.add(Map<String, dynamic>.from(item));
    }
  }
  return result;
}
