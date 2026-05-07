import 'api_service.dart';
import '../utils/role_utils.dart';

class AuthService {
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    String? cvUrl,
    String? linkedinUrl,
    String? additionalInfo,
    num? baseRate,
  }) async {
    final includeMentorFields = isMentorRole(role);
    return ApiService.post('/auth/signup', {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
      if (includeMentorFields) ...{
        'cvUrl': cvUrl,
        'linkedinUrl': linkedinUrl,
        'payoutAccountInfo': additionalInfo,
        'proposedHourlyRate': baseRate,
      },
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String email,
  }) async {
    return ApiService.post('/auth/google-login', {
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return ApiService.post('/auth/forgot-password', {
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return ApiService.post('/auth/reset-password/$token', {
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    return ApiService.postWithAuth('/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }, token);
  }

  static Future<Map<String, dynamic>> getCurrentUser({
    required String token,
  }) async {
    return ApiService.get('/auth/me', token);
  }
}
