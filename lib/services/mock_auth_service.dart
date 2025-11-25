class MockAuthService {
  // ตรงนี้คือ user สมมติ ใช้แทน Database/API
  final String _mockEmail = 'test@email.com';
  final String _mockPassword = '123456';

  Future<bool> login({required String email, required String password}) async {
    // ใส่ delay เล็กน้อยให้เหมือนเรียก API จริง
    await Future.delayed(const Duration(milliseconds: 800));
    return email == _mockEmail && password == _mockPassword;
  }
}
