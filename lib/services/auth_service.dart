abstract class AuthService {
  /// Returns null if successful, otherwise returns error message.
  Future<String?> register({required String email, required String password});

  /// Returns accessToken if successful.
  Future<AuthResponse> login({required String email, required String password});

  /// Returns AuthResponse with tokens.
  /// For Supabase, this handles verify + sync.
  Future<AuthResponse> verifyOtp(
      {required String email, required String token});

  Future<void> logout();

  Future<String?> refreshToken();

  /// Returns 'existing', 'new', or 'unknown'
  Future<String> checkEmailStatus(String email);

  Future<void> resendOtp(String email);

  Future<String?> getAccessToken();
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final dynamic user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });
}
