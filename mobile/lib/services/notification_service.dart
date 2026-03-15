import 'api_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getMyNotifications(String token) async {
    return ApiService.get('/notifications/me', token);
  }

  static Future<Map<String, dynamic>> getUnreadCount(String token) async {
    return ApiService.get('/notifications/me/unread-count', token);
  }

  static Future<Map<String, dynamic>> markAsRead(
    String token,
    String notificationId,
  ) async {
    return ApiService.postWithAuth(
      '/notifications/$notificationId/read',
      {},
      token,
    );
  }

  static Future<Map<String, dynamic>> markAllAsRead(String token) async {
    return ApiService.postWithAuth('/notifications/me/read-all', {}, token);
  }
}
