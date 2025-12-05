import 'package:medibuddy/widgets/login_button.dart';

class MockAuthService {
  // ตรงนี้คือ user สมมติ ใช้แทน Database/API
  final String _mockEmail = 'test@email.com';
  final String _mockPassword = '123456';

  Future<bool> login({required String email, required String password}) async {
    return email == _mockEmail && password == _mockPassword;
  }
}
