import 'api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> updates,
  }) async {
    return ApiService.patchWithAuth('/profile', updates, token);
  }
}
