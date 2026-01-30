import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medibuddy/Model/medicine_regimen_model.dart';

class RegimenApiException implements Exception {
  final String message;
  final int? statusCode;

  RegimenApiException(this.message, {this.statusCode});

  @override
  String toString() => 'RegimenApiException($statusCode): $message';
}

class RegimenApiService {
  RegimenApiService({
    http.Client? client,
    SupabaseClient? supabaseClient,
  })  : _client = client ?? http.Client(),
        _supabase = supabaseClient ?? Supabase.instance.client;

  final http.Client _client;
  final SupabaseClient _supabase;

  String _baseUrl() {
    final base = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (base.isEmpty) {
      throw RegimenApiException('API_BASE_URL is missing in .env');
    }
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  String _requireAccessToken() {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw RegimenApiException('Please login again (missing access token).');
    }
    return token;
  }

  Future<MedicineRegimenResponse> createMedicineRegimen({
    required int mediListId,
    required String scheduleType, // DAILY/WEEKLY/INTERVAL/CYCLE
    required DateTime startDateUtc,
    DateTime? endDateUtc, // only DAILY
    List<int>? daysOfWeek, // only WEEKLY
    int? intervalDays, // only INTERVAL
    int? cycleOnDays, // only CYCLE
    int? cycleBreakDays, // only CYCLE
    required List<MedicineRegimenTime> times,
  }) async {
    final token = _requireAccessToken();
    final url =
        Uri.parse('${_baseUrl()}/api/mobile/v1/medicine-regimen/create');

    final body = _buildCreateBody(
      mediListId: mediListId,
      scheduleType: scheduleType,
      startDateUtc: startDateUtc,
      endDateUtc: endDateUtc,
      daysOfWeek: daysOfWeek,
      intervalDays: intervalDays,
      cycleOnDays: cycleOnDays,
      cycleBreakDays: cycleBreakDays,
      times: times,
    );

    debugPrint('📦 regimen request=${jsonEncode(body)}');

    final res = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    debugPrint('📡 regimen status=${res.statusCode}');
    debugPrint('📦 regimen body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      debugPrint('❌ regimen error=$message');
      throw RegimenApiException(
        message ?? 'Create regimen failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw RegimenApiException('Invalid response format (expected object).');
    }

    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : Map<String, dynamic>.from(decoded as Map);

    final response = MedicineRegimenResponse.fromJson(data);
    debugPrint('✅ regimen created id=${response.mediRegimenId}');
    return response;
  }

  Future<MedicineRegimenResponse> updateRegimen({
    required int mediRegimenId,
    required String scheduleType, // DAILY/WEEKLY/INTERVAL/CYCLE
    DateTime? startDateUtc,
    DateTime? endDateUtc,
    List<String>? daysOfWeek, // "MON".."SUN"
    int? intervalDays,
    int? cycleOnDays,
    int? cycleBreakDays,
    List<MedicineRegimenTime>? times,
  }) async {
    final token = _requireAccessToken();
    final url =
        Uri.parse('${_baseUrl()}/api/mobile/v1/medicine-regimen/update');

    final body = _buildUpdateBody(
      mediRegimenId: mediRegimenId,
      scheduleType: scheduleType,
      startDateUtc: startDateUtc,
      endDateUtc: endDateUtc,
      daysOfWeek: daysOfWeek,
      intervalDays: intervalDays,
      cycleOnDays: cycleOnDays,
      cycleBreakDays: cycleBreakDays,
      times: times,
    );

    print('📦 regimen/update payload=${jsonEncode(body)}');

    final res = await _client.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('📡 regimen/update status=${res.statusCode}');
    print('📦 regimen/update body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      debugPrint('❌ regimen update error=$message');
      throw RegimenApiException(
        message ?? 'Update regimen failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw RegimenApiException('Invalid response format (expected object).');
    }

    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : Map<String, dynamic>.from(decoded as Map);

    final response = MedicineRegimenResponse.fromJson(data);
    debugPrint('✅ regimen updated id=${response.mediRegimenId}');
    return response;
  }

  Future<void> deleteRegimen({required int mediRegimenId}) async {
    if (mediRegimenId <= 0) {
      throw RegimenApiException('mediRegimenId must be a positive integer.');
    }
    final token = _requireAccessToken();
    final url = Uri.parse(
      '${_baseUrl()}/api/mobile/v1/medicine-regimen/delete?mediRegimenId=$mediRegimenId',
    );

    debugPrint('📦 regimen delete request id=$mediRegimenId');

    final res = await _client.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('📡 regimen delete status=${res.statusCode}');
    debugPrint('📦 regimen delete body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      debugPrint('❌ regimen delete error=$message');
      throw RegimenApiException(
        message ?? 'Delete regimen failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
  }

  Future<MedicineRegimenDetailResponse> getRegimenDetail({
    required int mediRegimenId,
  }) async {
    if (mediRegimenId <= 0) {
      throw RegimenApiException('mediRegimenId must be a positive integer.');
    }
    final token = _requireAccessToken();
    final url = Uri.parse(
      '${_baseUrl()}/api/mobile/v1/medicine-regimen/detail?mediRegimenId=$mediRegimenId',
    );

    final res = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📡 regimen/detail status=${res.statusCode}');
    print('📦 regimen/detail body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      debugPrint('❌ regimen detail error=$message');
      throw RegimenApiException(
        message ?? 'Get regimen detail failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw RegimenApiException('Invalid response format (expected object).');
    }

    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : Map<String, dynamic>.from(decoded as Map);

    return MedicineRegimenDetailResponse.fromJson(data);
  }

  Future<MedicineRegimenListResponse> getRegimensByProfileId({
    required int profileId,
  }) async {
    if (profileId <= 0) {
      throw RegimenApiException('profileId must be a positive integer.');
    }
    final token = _requireAccessToken();
    final url = Uri.parse(
      '${_baseUrl()}/api/mobile/v1/medicine-regimen/list?profileId=$profileId',
    );

    debugPrint('\u{1F9EA} regimen/list profileId=$profileId');

    final res = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('\u{1F4E1} regimen/list status=${res.statusCode}');
    debugPrint('\u{1F4E6} regimen/list body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      throw RegimenApiException(
        message ?? 'Get regimen list failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw RegimenApiException('Invalid response format (expected object).');
    }

    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : Map<String, dynamic>.from(decoded as Map);

    return MedicineRegimenListResponse.fromJson(data);
  }

//------------------ list regimen ----------------------------------------
  Future<MedicineRegimenListResponse> getRegimensByMedicineListId({
    required int medicineListId,
  }) async {
    if (medicineListId <= 0) {
      throw RegimenApiException('medicineListId must be a positive integer.');
    }
    final token = _requireAccessToken();
    final url = Uri.parse(
      '${_baseUrl()}/api/mobile/v1/medicine-regimen/list/by-medicine?medicineListId=$medicineListId',
    );

    final res = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('\u{1F4E1} home regimen list status=${res.statusCode}');
    debugPrint('\u{1F4E6} home regimen list body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final parsed = _readErrorMessage(res.body);
      final friendly = _friendlyAuthError(res.statusCode);
      final message = parsed ?? friendly;
      throw RegimenApiException(
        message ?? 'Get regimen list failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw RegimenApiException('Invalid response format (expected object).');
    }

    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : Map<String, dynamic>.from(decoded as Map);

    return MedicineRegimenListResponse.fromJson(data);
  }

  Map<String, dynamic> _buildCreateBody({
    required int mediListId,
    required String scheduleType,
    required DateTime startDateUtc,
    DateTime? endDateUtc,
    List<int>? daysOfWeek,
    int? intervalDays,
    int? cycleOnDays,
    int? cycleBreakDays,
    required List<MedicineRegimenTime> times,
  }) {
    if (mediListId <= 0) {
      throw RegimenApiException('mediListId must be a positive integer.');
    }

    if (times.isEmpty) {
      throw RegimenApiException('times must contain at least 1 item.');
    }

    final normalized = scheduleType.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw RegimenApiException('scheduleType is required.');
    }

    final body = <String, dynamic>{
      'mediListId': mediListId,
      'scheduleType': normalized,
      'startDate': _iso(startDateUtc),
      'times': times.map((t) => t.toJson()).toList(),
    };

    switch (normalized) {
      case 'DAILY':
        if (endDateUtc == null) {
          throw RegimenApiException('DAILY requires endDate.');
        }
        body['endDate'] = _iso(endDateUtc);
        break;
      case 'WEEKLY':
        if (daysOfWeek == null || daysOfWeek.isEmpty) {
          throw RegimenApiException('WEEKLY requires daysOfWeek.');
        }
        body['daysOfWeek'] = daysOfWeek;
        break;
      case 'INTERVAL':
        if (intervalDays == null || intervalDays < 1) {
          throw RegimenApiException('INTERVAL requires intervalDays >= 1.');
        }
        body['intervalDays'] = intervalDays;
        break;
      case 'CYCLE':
        if (cycleOnDays == null || cycleOnDays < 1) {
          throw RegimenApiException('CYCLE requires cycleOnDays >= 1.');
        }
        if (cycleBreakDays == null || cycleBreakDays < 1) {
          throw RegimenApiException('CYCLE requires cycleBreakDays >= 1.');
        }
        body['cycleOnDays'] = cycleOnDays;
        body['cycleBreakDays'] = cycleBreakDays;
        break;
      default:
        throw RegimenApiException('Unsupported scheduleType: $scheduleType');
    }

    return body;
  }

  Map<String, dynamic> _buildUpdateBody({
    required int mediRegimenId,
    required String scheduleType,
    DateTime? startDateUtc,
    DateTime? endDateUtc,
    List<String>? daysOfWeek,
    int? intervalDays,
    int? cycleOnDays,
    int? cycleBreakDays,
    List<MedicineRegimenTime>? times,
  }) {
    if (mediRegimenId <= 0) {
      throw RegimenApiException('mediRegimenId must be a positive integer.');
    }

    final normalized = scheduleType.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw RegimenApiException('scheduleType is required.');
    }

    final body = <String, dynamic>{
      'mediRegimenId': mediRegimenId,
      'scheduleType': normalized,
    };

    if (startDateUtc != null) {
      body['startDate'] = _iso(startDateUtc);
    }

    if (times != null) {
      if (times.isEmpty) {
        throw RegimenApiException('times must contain at least 1 item.');
      }
      body['times'] = times.map((t) => t.toJson()).toList();
    }

    switch (normalized) {
      case 'DAILY':
        if (endDateUtc == null) {
          throw RegimenApiException('DAILY requires endDate.');
        }
        body['endDate'] = _iso(endDateUtc);
        break;
      case 'WEEKLY':
        if (daysOfWeek == null || daysOfWeek.isEmpty) {
          throw RegimenApiException('WEEKLY requires daysOfWeek.');
        }
        final normalizedDays = _normalizeWeekdayCodes(daysOfWeek);
        if (normalizedDays.isEmpty) {
          throw RegimenApiException('WEEKLY requires valid daysOfWeek.');
        }
        body['daysOfWeek'] = normalizedDays;
        if (endDateUtc != null) {
          body['endDate'] = _iso(endDateUtc);
        }
        break;
      case 'INTERVAL':
        if (intervalDays == null || intervalDays < 1) {
          throw RegimenApiException('INTERVAL requires intervalDays >= 1.');
        }
        body['intervalDays'] = intervalDays;
        if (endDateUtc != null) {
          body['endDate'] = _iso(endDateUtc);
        }
        break;
      case 'CYCLE':
        if (cycleOnDays == null || cycleOnDays < 1) {
          throw RegimenApiException('CYCLE requires cycleOnDays >= 1.');
        }
        if (cycleBreakDays == null || cycleBreakDays < 1) {
          throw RegimenApiException('CYCLE requires cycleBreakDays >= 1.');
        }
        body['cycleOnDays'] = cycleOnDays;
        body['cycleBreakDays'] = cycleBreakDays;
        if (endDateUtc != null) {
          body['endDate'] = _iso(endDateUtc);
        }
        break;
      default:
        throw RegimenApiException('Unsupported scheduleType: $scheduleType');
    }

    return body;
  }

  List<String> _normalizeWeekdayCodes(List<String> days) {
    const valid = {
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    };
    final result = <String>[];
    final seen = <String>{};
    for (final day in days) {
      final normalized = day.trim().toUpperCase();
      if (valid.contains(normalized) && !seen.contains(normalized)) {
        seen.add(normalized);
        result.add(normalized);
      }
    }
    return result;
  }

  String _iso(DateTime utc) => utc.toUtc().toIso8601String();

  String? _friendlyAuthError(int statusCode) {
    if (statusCode == 401) return 'Unauthorized. Please login again.';
    if (statusCode == 403) return 'Not allowed to modify this regimen.';
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
