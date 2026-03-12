import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'token_manager.dart';

class TutorialService {
  static Future<bool> isTutorialDone() async {
    try {
      final token = await TokenManager.getValidAccessToken();
      if (token == null) return false;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final dio = Dio(BaseOptions(baseUrl: baseUrl));

      final response = await dio.get(
        '/api/mobile/v1/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final responseData = response.data;
      debugPrint('[TutorialService] /auth/me response: $responseData');

      // Handle both flat and nested response structures
      dynamic tutorialDone;
      if (responseData is Map) {
        tutorialDone = responseData['tutorialDone'];
        // Check nested under 'user'
        if (tutorialDone == null && responseData['user'] is Map) {
          tutorialDone = responseData['user']['tutorialDone'];
        }
      }

      debugPrint(
          '[-------TutorialService] tutorialDone = $tutorialDone (type: ${tutorialDone.runtimeType})');
      return tutorialDone == true;
    } catch (e) {
      debugPrint(
          '----------[TutorialService] Failed to fetch tutorial status: $e');
      return false;
    }
  }

  static Future<void> setTutorialDone() async {
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
      debugPrint('Failed to update tutorial status to server: $e');
    }
  }
}
