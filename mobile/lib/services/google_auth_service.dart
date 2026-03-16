import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService { 
  static String get baseUrl => '${ApiService.baseUrl}/auth'; 

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

      return {'success': true, 'email': user.email};
    } catch (e) {
      print("Google Sign In Error: $e");
      return {'success': false, 'message': 'Google Sign-In Error. Note: You must configure SHA-1 keys in Firebase mapped to your app package name for this to work on Android.'};
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
