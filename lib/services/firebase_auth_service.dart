import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_manager.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<String?> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firebase automatically signs in after creation, but we might want to send verification email
      await _auth.currentUser?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Login failed: No user');

    final token = await user.getIdToken();
    if (token == null)
      throw Exception('Login failed: Failed to retrieve token');
    AuthManager.accessToken = token;

    return AuthResponse(
      accessToken: token,
      refreshToken: null, // Firebase handles refresh internally
      user: user,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google Credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          AuthManager.accessToken = token;
          print('🔥 Firebase Google Login Success: ${user.email}');
        }
      }
    } catch (e) {
      print('🔥 Firebase Google Login Error: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    // Firebase defaults to Link Verification for email, not OTP.
    // However, if you use Phone Auth, you verify OTP.
    throw Exception(
        'Firebase normally uses Email Link Verification, not OTP code. Please check email for verification link.');
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    AuthManager.accessToken = null;
  }

  @override
  Future<String?> refreshToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final token = await user.getIdToken(true); // check refresh
      AuthManager.accessToken = token;
      return token;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    AuthManager.accessToken = token;
    return token;
  }

  @override
  Future<String> checkEmailStatus(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) return 'existing';
      return 'new';
    } catch (e) {
      print('Check email error: $e');
      // Assume new if error or not found
      return 'new';
    }
  }

  @override
  Future<void> resendOtp(String email) async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw Exception('User not logged in or already verified');
    }
  }
}
