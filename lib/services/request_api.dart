import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<void> sendUserRequest({
  required String accessToken,
  required String requestType,
  required String requestTitle,
  String requestDetails = '',
  File? pictureFile,
}) async {
  final _baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
  if (_baseUrl.isEmpty) throw Exception('API_BASE_URL is empty');

  final type = requestType.trim();
  final title = requestTitle.trim();
  final details = requestDetails.trim();

  if (type.isEmpty) throw Exception('requestType is required');
  if (title.isEmpty) throw Exception('requestTitle is required');

  // requestDetails required except ADD_MEDICINE
  if (type != 'ADD_MEDICINE' && details.isEmpty) {
    throw Exception('requestDetails is required for requestType=$type');
  }

  final uri = Uri.parse(
      '${_baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl}'
      '/api/mobile/v1/user-request/create');

  final req = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $accessToken'
    ..headers['Accept'] = 'application/json'
    ..fields['requestType'] = type
    ..fields['requestTitle'] = title
    ..fields['requestDetails'] = details;

  if (pictureFile != null) {
    final mime = _guessImageMime(pictureFile.path);
    req.files.add(await http.MultipartFile.fromPath(
      'picture',
      pictureFile.path,
      contentType: MediaType(mime.$1, mime.$2),
    ));
  }

  final res = await req.send();
  final body = await res.stream.bytesToString();

  if (kDebugMode) {
    debugPrint('📡 status=${res.statusCode}');
    debugPrint('📦 body=$body');
  }

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(body.isEmpty ? 'Request failed' : body);
  }
}

(String, String) _guessImageMime(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return ('image', 'png');
  if (p.endsWith('.webp')) return ('image', 'webp');
  return ('image', 'jpeg');
}
