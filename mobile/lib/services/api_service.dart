import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://YOUR_IP:5000/api
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Runtime default when API_BASE_URL is not provided.
  // Physical device on local network: use the host machine's LAN IP.
  // To override, run with: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:5000/api
  static String get _lanIp => '192.168.1.189';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:5000/api';
    return 'http://$_lanIp:5000/api';
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Object body,
  ) async {
    try {
      final url = '$baseUrl$endpoint';
      print('DEBUG: Calling API -> $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> postWithAuth(
    String endpoint,
    Object body,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> patchWithAuth(
    String endpoint,
    Object body,
    String token,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> putWithAuth(
    String endpoint,
    Object body,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPublic(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
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
  }

  static Future<Map<String, dynamic>> getPublicMentors() async {
    return getPublic('/mentors/public');
  }

  static Future<Map<String, dynamic>> getPublicMentorSlots({
    required String mentorId,
    required String date,
    required int durationMinutes,
  }) async {
    final endpoint =
        '/mentors/public/$mentorId/available-slots?date=$date&durationMinutes=$durationMinutes';
    return getPublic(endpoint);
  }

  static Future<Map<String, dynamic>> createSessionBooking({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return postWithAuth('/mentor-sessions', payload, token);
  }

  static Future<Map<String, dynamic>> createSessionFawryCheckout({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return postWithAuth('/mentor-sessions/fawry-checkout', payload, token);
  }

  static Future<Map<String, dynamic>> getPaymentStatus({
    required String token,
    required String transactionId,
  }) async {
    return get('/payments/status/$transactionId', token);
  }

  static Future<Map<String, dynamic>> getSessionTimer({
    required String token,
    required String sessionId,
  }) async {
    return get('/mentor-sessions/$sessionId/timer', token);
  }
}
