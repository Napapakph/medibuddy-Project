import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_manager.dart';

class TutorialService {
  static const _storage = FlutterSecureStorage();
  static const String _tutorialKey = 'tutorial_done';

  static Future<bool> isTutorialDone() async {
    final val = await _storage.read(key: _tutorialKey);
    return val == 'true';
  }

  static Future<void> setTutorialDone() async {
    await _storage.write(key: _tutorialKey, value: 'true');
    try {
      final token = await TokenManager.getValidAccessToken();
      if (token != null) {
        final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
        final dio = Dio(BaseOptions(baseUrl: baseUrl));
        await dio.patch(
          '/api/mobile/v1/users/tutorial-status',
          data: {'tutorialDone': true},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      print('Failed to update tutorial status to server: $e');
    }
  }
}
