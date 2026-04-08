import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

class GoogleAuthService { 
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Force sign out first to ensure the account picker shows up every time
      // This is helpful during testing so you can switch accounts
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user == null) {
        return {'success': false, 'message': 'User cancelled'};
      }

      final email = user.email;
      return AuthService.googleLogin(email: email);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
