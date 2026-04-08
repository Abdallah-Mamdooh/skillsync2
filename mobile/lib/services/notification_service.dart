import 'api_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getMyNotifications(String token) async {
    return ApiService.get('/notifications/me', token);
  }

  static Future<Map<String, dynamic>> markAsRead(
    String token,
    String notificationId,
  ) async {
    return ApiService.patchWithAuth(
      '/notifications/$notificationId/read',
      {},
      token,
    );
  }

  static Future<Map<String, dynamic>> markAllAsRead(String token) async {
    return ApiService.patchWithAuth('/notifications/read-all', {}, token);
  }
}
