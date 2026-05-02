import 'api_service.dart';

class MentorService {
  /// Fetches the current user's mentor profile
  /// Backend: GET /api/mentor/me
  static Future<Map<String, dynamic>> getMyProfile(String token) async {
    return ApiService.get('/mentors/me', token);
  }

  /// Updates the mentor's own profile
  /// Backend: PUT /api/mentor/me
  static Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> updates,
  ) async {
    return ApiService.putWithAuth('/mentors/me', updates, token);
  }

  /// Fetches pending session requests for the mentor
  /// Backend: GET /api/mentor-sessions/incoming
  static Future<Map<String, dynamic>> getIncomingSessions(String token) async {
    return ApiService.get('/mentor-sessions/incoming', token);
  }

  /// Fetches all sessions for the mentor
  /// Backend: GET /api/mentor-sessions/me
  static Future<Map<String, dynamic>> getMySessions(String token) async {
    return ApiService.get('/mentor-sessions/me', token);
  }

  /// Starts a session
  /// Backend: POST /api/mentor-sessions/:sessionId/start
  static Future<Map<String, dynamic>> startSession(
    String token,
    String sessionId,
  ) async {
    return ApiService.postWithAuth('/mentor-sessions/$sessionId/start', {}, token);
  }

  /// Completes a session
  /// Backend: POST /api/mentor-sessions/:sessionId/complete
  static Future<Map<String, dynamic>> completeSession(
    String token,
    String sessionId,
  ) async {
    return ApiService.postWithAuth('/mentor-sessions/$sessionId/complete', {}, token);
  }

  /// Gets session details by ID
  /// Backend: GET /api/mentor-sessions/:sessionId
  static Future<Map<String, dynamic>> getSessionById(
    String token,
    String sessionId,
  ) async {
    return ApiService.get('/mentor-sessions/$sessionId', token);
  }

  /// Updates mentor availability status
  /// Backend: PUT /api/mentor/me with isAvailable field
  static Future<Map<String, dynamic>> updateAvailability(
    String token,
    bool isAvailable,
  ) async {
    return ApiService.putWithAuth(
      '/mentors/me',
      {'isAvailable': isAvailable},
      token,
    );
  }

  static Map<String, dynamic> normalizeSession(Map<String, dynamic> session) {
    final mentor = session['mentor'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(session['mentor'])
        : <String, dynamic>{};
    final user = session['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(session['user'])
        : <String, dynamic>{};

    return {
      ...session,
      'id': session['id'] ?? session['_id'] ?? '',
      'mentor': mentor,
      'user': user,
      'method': session['method'] ?? 'chat',
      'status': session['status'] ?? 'scheduled',
      'durationMinutes': session['durationMinutes'] ?? 0,
      'scheduledStartTime': session['scheduledStartTime'] ?? '',
      'scheduledEndTime': session['scheduledEndTime'] ?? '',
      'pricing': session['pricing'] ?? <String, dynamic>{},
    };
  }
}
