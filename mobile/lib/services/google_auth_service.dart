import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

      final email = user.email;

      final response = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Backend error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Google Sign In Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
