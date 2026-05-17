import 'api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  /// Fetches all sessions for the logged-in user, filtered to chat-method only.
  /// Backend: GET /api/Mentor-sessions/me
  static Future<Map<String, dynamic>> getMyChatSessions(String token) async {
    final response = await ApiService.get('/mentor-sessions/me', token);
    if (response['success'] != true) return response;
    final raw = response['data'];
    final sessions = raw is List ? raw : <dynamic>[];
    return {
      ...response,
      'data': sessions
          .whereType<Map>()
          .map((s) => normalizeSession(Map<String, dynamic>.from(s)))
          .toList(),
    };
  }

  /// Fetches all messages for a given chat session.
  /// Backend: GET /api/chat/:sessionId/messages
  static Future<Map<String, dynamic>> getChatMessages(
    String token,
    String sessionId,
  ) async {
    return ApiService.get('/chat/$sessionId/messages', token);
  }

  /// Sends a text message in a chat session.
  /// Backend: POST /api/chat/:sessionId/messages
  static Future<Map<String, dynamic>> sendMessage(
    String token,
    String sessionId,
    String content,
  ) async {
    return ApiService.postWithAuth(
      '/chat/$sessionId/messages',
      {'content': content},
      token,
    );
  }

  /// Sends a file in a chat session.
  static Future<Map<String, dynamic>> sendFile(
    String token,
    String sessionId,
    File file,
    String fileName,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/chat/$sessionId/messages'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path,
            filename: fileName),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Server error',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Map<String, dynamic> normalizeSession(Map<String, dynamic> session) {
    final mentor = session['mentor'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(session['mentor'])
        : <String, dynamic>{};
    final requester = session['requester'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(session['requester'])
        : <String, dynamic>{};
    final id = session['id'] ?? session['_id'] ?? '';
    return {
      ...session,
      'id': id,
      '_id': id,
      'mentorId': mentor,
      'requester': requester,
      'status': session['status'] ?? 'scheduled',
      'method': session['method'] ?? 'chat',
      'sessionDuration': session['durationMinutes']?.toString() ?? '',
      'updatedAt': session['updatedAt'] ??
          session['scheduledStartTime'] ??
          DateTime.now().toIso8601String(),
    };
  }
}
